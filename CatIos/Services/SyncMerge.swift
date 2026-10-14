//
//  SyncMerge.swift
//  CatIos — three-way merge used by HouseholdSync when the device and the
//  server both changed since the last successful sync.
//
//  For every record (matched by id) we compare local and remote against the
//  last synced copy (the "baseline"):
//    • changed only on one side          → take that side
//    • changed on both sides             → this device wins (the user's latest edit here)
//    • deleted on one side, untouched on the other → delete
//    • deleted on one side, edited on the other    → keep the edit
//

import Foundation

protocol SyncRecord: Equatable {
    var id: UUID { get }
}

extension APIPet: SyncRecord {}
extension APICareTask: SyncRecord {}
extension APIHealthRecord: SyncRecord {}
extension APIFood: SyncRecord {}
extension APIFeeding: SyncRecord {}
extension APIWeight: SyncRecord {}
extension APIBehavior: SyncRecord {}
extension APITaskTemplate: SyncRecord {}

enum SyncMerge {
    static func merge<T: SyncRecord>(local: [T], remote: [T], baseline: [T]) -> [T] {
        let base = Dictionary(baseline.map { ($0.id, $0) }, uniquingKeysWith: { a, _ in a })
        let remoteById = Dictionary(remote.map { ($0.id, $0) }, uniquingKeysWith: { a, _ in a })
        let localIds = Set(local.map(\.id))
        var result: [T] = []

        for item in local {
            let original = base[item.id]
            let localChanged = original != item
            if let theirs = remoteById[item.id] {
                result.append(localChanged ? item : theirs)
            } else if original == nil || localChanged {
                // New on this device, or edited here while deleted remotely: keep it.
                result.append(item)
            }
            // else: deleted remotely and untouched here → drop.
        }

        for theirs in remote where !localIds.contains(theirs.id) {
            if let original = base[theirs.id] {
                // Deleted on this device; keep only if the server edited it since.
                if original != theirs { result.append(theirs) }
            } else {
                result.append(theirs) // new on the server
            }
        }
        return result
    }

    static func merge(local: APISyncSnapshot, remote: APISyncSnapshot, baseline: APISyncSnapshot?) -> APISyncSnapshot {
        let b = baseline
        var merged = APISyncSnapshot(
            pets: merge(local: local.pets, remote: remote.pets, baseline: b?.pets ?? []),
            tasks: merge(local: local.tasks, remote: remote.tasks, baseline: b?.tasks ?? []),
            healthRecords: merge(local: local.healthRecords, remote: remote.healthRecords, baseline: b?.healthRecords ?? []),
            reminders: mergeStrings(local.reminders ?? [], remote.reminders ?? []),
            foods: merge(local: local.foods ?? [], remote: remote.foods ?? [], baseline: b?.foods ?? []),
            feedings: merge(local: local.feedings ?? [], remote: remote.feedings ?? [], baseline: b?.feedings ?? []),
            weights: merge(local: local.weights ?? [], remote: remote.weights ?? [], baseline: b?.weights ?? []),
            behaviors: merge(local: local.behaviors ?? [], remote: remote.behaviors ?? [], baseline: b?.behaviors ?? []),
            taskTemplates: merge(local: local.taskTemplates ?? [], remote: remote.taskTemplates ?? [], baseline: b?.taskTemplates ?? [])
        )
        merged.revision = remote.revision
        merged.householdRole = remote.householdRole
        return merged
    }

    private static func mergeStrings(_ a: [String], _ b: [String]) -> [String] {
        var seen = Set<String>()
        return (a + b).filter { seen.insert($0).inserted }
    }
}
