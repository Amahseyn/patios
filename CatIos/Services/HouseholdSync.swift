//
//  HouseholdSync.swift
//  CatIos — offline-first sync between the on-device SQLite stores and the API.
//
//  The UI only ever reads the local stores. Every edit is saved to SQLite first,
//  marked as "pending", and pushed in the background when the user is signed in
//  and the network is available. Pending state, the server revision, and the
//  last synced snapshot survive app restarts, so nothing is lost offline.
//

import Foundation
import Combine
import Network
import UIKit

extension Notification.Name {
    static let householdDidChange = Notification.Name("patios.householdDidChange")
}

@MainActor
final class HouseholdSync: ObservableObject {
    static let shared = HouseholdSync()

    @Published var isSyncing = false
    @Published var lastError: String?
    @Published var lastSyncedAt: Date?
    @Published var apiReachable: Bool?
    @Published var statusText = "Saved on this device"
    @Published private(set) var hasPendingChanges = false
    @Published private(set) var isOnline = true
    @Published private(set) var revision = 0
    @Published private(set) var householdRole = "owner"

    var canMutate: Bool {
        guard AuthSession.shared.isSignedIn else { return true }
        if AuthSession.shared.currentUser?.role == "viewer" { return false }
        return householdRole != "viewer"
    }

    private enum Key {
        static let revision = "sync.revision"
        static let pending = "sync.pending"
        static let lastSyncedAt = "sync.lastSyncedAt"
        static let baseline = "sync.baseline"
        static let role = "sync.role"
    }

    private let database: AppDatabase
    private let monitor = NWPathMonitor()
    private var pushTask: Task<Void, Never>?
    private var retryTask: Task<Void, Never>?
    private var retryAttempt = 0
    private var applyingRemote = false
    private var observing = false
    private let maxConflictRetries = 3

    init(database: AppDatabase = .shared) {
        self.database = database
        revision = Int(database.value(for: Key.revision) ?? "") ?? 0
        hasPendingChanges = database.value(for: Key.pending) == "1"
        householdRole = database.value(for: Key.role) ?? "owner"
        if let raw = database.value(for: Key.lastSyncedAt), let seconds = Double(raw) {
            lastSyncedAt = Date(timeIntervalSince1970: seconds)
        }
        refreshStatus()
    }

    // MARK: - Lifecycle

    func connect() async {
        let reachable = await APIClient.shared.ping()
        apiReachable = reachable
        guard AuthSession.shared.isSignedIn else {
            statusText = reachable
                ? "Pet Care is ready to sync. Sign in to connect this phone."
                : "Saved on this device"
            return
        }
        guard reachable else {
            refreshStatus()
            scheduleRetry()
            return
        }
        await syncNow()
        await AssistantSessionStore.shared.pullFromAccount()
    }

    func noteSignedOut() {
        revision = 0
        householdRole = "owner"
        database.setValue("0", for: Key.revision)
        database.setValue("", for: Key.baseline)
        retryTask?.cancel()
    }

    /// Starts listening for local edits, network changes, and app foregrounding.
    func observeStores() {
        guard !observing else { return }
        observing = true
        // Delivered synchronously (stores post on the main actor) so `applyingRemote`
        // is still set while server data is being written locally.
        NotificationCenter.default.addObserver(forName: .householdDidChange, object: nil, queue: nil) { [weak self] _ in
            MainActor.assumeIsolated { self?.localDataChanged() }
        }
        NotificationCenter.default.addObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor in await self?.syncNow() }
        }
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in self?.networkChanged(online: path.status == .satisfied) }
        }
        monitor.start(queue: DispatchQueue(label: "patios.network"))
    }

    // MARK: - Local changes

    private func localDataChanged() {
        guard !applyingRemote else { return }
        setPending(true)
        schedulePush()
    }

    func schedulePush() {
        guard AuthSession.shared.isSignedIn, canMutate, !applyingRemote else { return }
        pushTask?.cancel()
        pushTask = Task {
            try? await Task.sleep(nanoseconds: 700_000_000)
            guard !Task.isCancelled else { return }
            await pushNow()
        }
    }

    private func networkChanged(online: Bool) {
        let cameBack = online && !isOnline
        isOnline = online
        refreshStatus()
        if cameBack, hasPendingChanges {
            Task { await syncNow() }
        }
    }

    // MARK: - Sync

    /// Pull-to-refresh entry point. Never discards unsynced local edits.
    func pullNow() async {
        await syncNow()
    }

    /// Pushes pending edits (merging if the server moved on), otherwise pulls.
    func syncNow() async {
        guard AuthSession.shared.isSignedIn, !isSyncing else { return }
        if hasPendingChanges && canMutate {
            await pushNow()
        } else {
            await pull()
        }
    }

    func pushNow() async {
        guard AuthSession.shared.isSignedIn, canMutate else { return }
        guard isOnline else { refreshStatus(); return }
        isSyncing = true
        defer { isSyncing = false }

        var snapshot = localSnapshot()
        snapshot.revision = revision
        for _ in 0..<maxConflictRetries {
            do {
                let saved: APISyncSnapshot = try await APIClient.shared.send("PUT", path: "sync", body: snapshot)
                markSynced(saved, baseline: snapshot)
                return
            } catch APIError.conflict {
                // Someone else changed the household: merge and try again.
                do {
                    let remote: APISyncSnapshot = try await APIClient.shared.send("GET", path: "sync")
                    var merged = SyncMerge.merge(local: snapshot, remote: remote, baseline: loadBaseline())
                    apply(merged, keepPending: true)
                    merged.revision = remote.revision ?? revision
                    snapshot = merged
                } catch {
                    failed(error)
                    return
                }
            } catch {
                failed(error)
                return
            }
        }
        failed(APIError.conflict)
    }

    private func pull() async {
        isSyncing = true
        defer { isSyncing = false }
        do {
            let remote: APISyncSnapshot = try await APIClient.shared.send("GET", path: "sync")
            if hasPendingChanges {
                // An edit happened while the request was in flight: merge instead of overwrite.
                let merged = SyncMerge.merge(local: localSnapshot(), remote: remote, baseline: loadBaseline())
                apply(merged, keepPending: true)
                saveRevision(remote.revision)
                isSyncing = false
                await pushNow()
                return
            }
            apply(remote)
            markSynced(remote, baseline: remote)
        } catch {
            failed(error)
        }
    }

    /// First sign-in on this phone: combine local and account data, never drop either.
    func reconcileAfterSignIn() async {
        guard AuthSession.shared.isSignedIn else { return }
        isSyncing = true
        do {
            let remote: APISyncSnapshot = try await APIClient.shared.send("GET", path: "sync")
            let merged = SyncMerge.merge(local: localSnapshot(), remote: remote, baseline: nil)
            apply(merged, keepPending: true)
            saveRevision(remote.revision)
            setPending(true)
            isSyncing = false
            await pushNow()
        } catch {
            isSyncing = false
            failed(error)
        }
    }

    // MARK: - Applying data

    func apply(_ snapshot: APISyncSnapshot, keepPending: Bool = false) {
        applyingRemote = true
        defer { applyingRemote = false }
        let pets = snapshot.pets.map { remote in
            APIMapping.pet(from: remote, existing: PetManager.shared.pets.first(where: { $0.id == remote.id }))
        }
        PetManager.shared.replaceFromRemote(pets)
        CareTaskStore.shared.replaceFromRemote(
            snapshot.tasks.map(APIMapping.task(from:)),
            templates: (snapshot.taskTemplates ?? []).map(APIMapping.taskTemplate(from:))
        )
        HealthRecordStore.shared.replaceFromRemote(
            snapshot.healthRecords.map(APIMapping.health(from:)),
            reminders: snapshot.reminders ?? []
        )
        if snapshot.foods != nil || snapshot.feedings != nil || snapshot.weights != nil || snapshot.behaviors != nil {
            WellnessStore.shared.replaceFromRemote(
                foods: (snapshot.foods ?? []).map(APIMapping.food(from:)),
                feedings: (snapshot.feedings ?? []).map(APIMapping.feeding(from:)),
                weights: (snapshot.weights ?? []).map(APIMapping.weight(from:)),
                behaviors: (snapshot.behaviors ?? []).map(APIMapping.behavior(from:))
            )
        }
        if let role = snapshot.householdRole {
            householdRole = role
            database.setValue(role, for: Key.role)
        }
        if !keepPending { saveRevision(snapshot.revision) }
    }

    private func localSnapshot() -> APISyncSnapshot {
        APISyncSnapshot(
            pets: PetManager.shared.pets.map(APIMapping.apiPet(from:)),
            tasks: CareTaskStore.shared.tasks.map(APIMapping.apiTask(from:)),
            healthRecords: HealthRecordStore.shared.records.map(APIMapping.apiHealth(from:)),
            reminders: HealthRecordStore.shared.reminders,
            foods: WellnessStore.shared.foods.map(APIMapping.apiFood(from:)),
            feedings: WellnessStore.shared.feedings.map(APIMapping.apiFeeding(from:)),
            weights: WellnessStore.shared.weights.map(APIMapping.apiWeight(from:)),
            behaviors: WellnessStore.shared.behaviors.map(APIMapping.apiBehavior(from:)),
            taskTemplates: CareTaskStore.shared.templates.map(APIMapping.apiTaskTemplate(from:))
        )
    }

    // MARK: - State bookkeeping

    private func markSynced(_ saved: APISyncSnapshot, baseline: APISyncSnapshot) {
        saveRevision(saved.revision)
        if let role = saved.householdRole {
            householdRole = role
            database.setValue(role, for: Key.role)
        }
        saveBaseline(baseline)
        setPending(false)
        lastError = nil
        lastSyncedAt = Date()
        database.setValue(String(Date().timeIntervalSince1970), for: Key.lastSyncedAt)
        retryAttempt = 0
        retryTask?.cancel()
        apiReachable = true
        refreshStatus()
    }

    private func failed(_ error: Error) {
        if case APIError.unreachable = error { apiReachable = false }
        lastError = error.localizedDescription
        refreshStatus()
        scheduleRetry()
    }

    /// Exponential backoff: 5s, 10s, 20s … capped at 5 minutes.
    private func scheduleRetry() {
        guard AuthSession.shared.isSignedIn else { return }
        retryTask?.cancel()
        let delay = min(300, 5 * pow(2, Double(retryAttempt)))
        retryAttempt += 1
        retryTask = Task {
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            guard !Task.isCancelled else { return }
            await syncNow()
        }
    }

    private func setPending(_ pending: Bool) {
        hasPendingChanges = pending
        database.setValue(pending ? "1" : "0", for: Key.pending)
        refreshStatus()
    }

    private func saveRevision(_ value: Int?) {
        guard let value else { return }
        revision = value
        database.setValue(String(value), for: Key.revision)
    }

    private func saveBaseline(_ snapshot: APISyncSnapshot) {
        guard let data = try? JSONEncoder().encode(snapshot),
              let text = String(data: data, encoding: .utf8) else { return }
        database.setValue(text, for: Key.baseline)
    }

    private func loadBaseline() -> APISyncSnapshot? {
        guard let text = database.value(for: Key.baseline), let data = text.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(APISyncSnapshot.self, from: data)
    }

    private func refreshStatus() {
        if isSyncing { statusText = "Syncing…"; return }
        guard AuthSession.shared.isSignedIn else { statusText = "Saved on this device"; return }
        if !isOnline {
            statusText = hasPendingChanges ? "Offline — changes saved, will sync when online" : "Offline — using data on this iPhone"
        } else if lastError != nil {
            statusText = hasPendingChanges ? "Changes saved on this iPhone — retrying sync" : "Couldn’t sync"
        } else if hasPendingChanges {
            statusText = "Changes saved — syncing soon"
        } else {
            statusText = "Synced with your account"
        }
    }
}
