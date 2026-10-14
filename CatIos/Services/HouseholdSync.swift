import Foundation
import Combine

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
    @Published private(set) var revision = 0
    @Published private(set) var householdRole = "owner"

    var canMutate: Bool {
        guard AuthSession.shared.isSignedIn else { return true }
        if AuthSession.shared.currentUser?.role == "viewer" { return false }
        return householdRole != "viewer"
    }

    private var pushTask: Task<Void, Never>?
    private var applyingRemote = false
    private var observing = false

    func connect() async {
        let reachable = await APIClient.shared.ping()
        apiReachable = reachable
        guard AuthSession.shared.isSignedIn else {
            if reachable {
                statusText = "Pet Care is ready to sync. Sign in to connect this phone."
            } else if lastSyncedAt == nil {
                statusText = "Saved on this device"
            }
            return
        }
        guard reachable else {
            lastError = APIError.unreachable.errorDescription
            statusText = "Can't reach Pet Care right now"
            return
        }
        await pullNow()
        await AssistantSessionStore.shared.pullFromAccount()
    }

    func noteSignedOut() {
        revision = 0
        householdRole = "owner"
    }

    func observeStores() {
        guard !observing else { return }
        observing = true
        NotificationCenter.default.addObserver(forName: .householdDidChange, object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor in
                self?.schedulePush()
            }
        }
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

    func pushNow() async {
        guard AuthSession.shared.isSignedIn, canMutate else { return }
        isSyncing = true
        defer { isSyncing = false }
        do {
            var snapshot = APISyncSnapshot(
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
            snapshot.revision = revision
            let saved: APISyncSnapshot = try await APIClient.shared.send("PUT", path: "sync", body: snapshot)
            if let savedRevision = saved.revision {
                revision = savedRevision
            }
            if let role = saved.householdRole {
                householdRole = role
            }
            lastError = nil
            lastSyncedAt = Date()
            statusText = "Synced with your account"
        } catch APIError.conflict {
            await pullNow()
        } catch {
            lastError = error.localizedDescription
            statusText = "Couldn’t sync"
        }
    }

    func pullNow() async {
        guard AuthSession.shared.isSignedIn else { return }
        isSyncing = true
        defer { isSyncing = false }
        do {
            let snapshot: APISyncSnapshot = try await APIClient.shared.send("GET", path: "sync")
            apply(snapshot)
            lastError = nil
            lastSyncedAt = Date()
            statusText = snapshot.pets.isEmpty ? "Account is empty — local pets will upload" : "Synced with your account"
        } catch {
            lastError = error.localizedDescription
            statusText = "Couldn’t sync"
        }
    }

    func reconcileAfterSignIn() async {
        guard AuthSession.shared.isSignedIn else { return }
        isSyncing = true
        defer { isSyncing = false }
        do {
            let snapshot: APISyncSnapshot = try await APIClient.shared.send("GET", path: "sync")
            if snapshot.pets.isEmpty {
                await pushNow()
                return
            }
            apply(snapshot)
            lastError = nil
            lastSyncedAt = Date()
            statusText = "Loaded household from your account"
        } catch {
            lastError = error.localizedDescription
            statusText = "Signed in, but sync failed"
        }
    }

    func apply(_ snapshot: APISyncSnapshot) {
        applyingRemote = true
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
            reminders: snapshot.reminders
        )
        if snapshot.foods != nil || snapshot.feedings != nil || snapshot.weights != nil || snapshot.behaviors != nil {
            WellnessStore.shared.replaceFromRemote(
                foods: (snapshot.foods ?? []).map(APIMapping.food(from:)),
                feedings: (snapshot.feedings ?? []).map(APIMapping.feeding(from:)),
                weights: (snapshot.weights ?? []).map(APIMapping.weight(from:)),
                behaviors: (snapshot.behaviors ?? []).map(APIMapping.behavior(from:))
            )
        }
        if let savedRevision = snapshot.revision {
            revision = savedRevision
        }
        if let role = snapshot.householdRole {
            householdRole = role
        }
        applyingRemote = false
    }
}
