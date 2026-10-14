//
//  AppDatabase.swift
//  CatIos
//
//  On-device SQLite database for pets, care tasks, and health records.
//

import Foundation
import SQLite3
import os

enum AppSupport {
    static func directory() -> URL {
        let fileManager = FileManager.default
        let base = (try? fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )) ?? fileManager.temporaryDirectory
        let directory = base.appendingPathComponent("Patios", isDirectory: true)
        try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }
}

private let sqliteTransient = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

@MainActor
final class AppDatabase {
    static let shared = AppDatabase()

    nonisolated(unsafe) private var db: OpaquePointer?
    private let logger = Logger(subsystem: "com.mohammadhashemi.CatIos", category: "database")
    private let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.sortedKeys]
        return encoder
    }()
    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()

    init(directory: URL = AppSupport.directory()) {
        let url = directory.appendingPathComponent("patios.sqlite")
        if sqlite3_open(url.path, &db) != SQLITE_OK {
            logger.error("Unable to open \(url.lastPathComponent, privacy: .public)")
            return
        }
        execute("PRAGMA foreign_keys = ON;")
        execute("PRAGMA journal_mode = WAL;")
        migrate()
        importLegacyJSONIfNeeded(in: directory)
    }

    deinit {
        sqlite3_close(db)
    }

    func loadPets() -> (pets: [PetProfile], selectedPetId: UUID)? {
        guard state("pets_ready") == "1" else { return nil }
        let pets: [PetProfile] = rows("SELECT payload FROM pets ORDER BY position ASC").compactMap { decode($0, as: PetProfile.self) }
        let selected = UUID(uuidString: state("selected_pet_id") ?? "") ?? pets.first?.id ?? PetProfile.mockLuna.id
        return (pets, selected)
    }

    func savePets(_ pets: [PetProfile], selectedPetId: UUID) {
        transaction {
            execute("DELETE FROM pets;")
            for (position, pet) in pets.enumerated() {
                guard let payload = encode(pet) else { continue }
                run(
                    "INSERT INTO pets (id, position, name, species, payload) VALUES (?, ?, ?, ?, ?);",
                    bindings: [.text(pet.id.uuidString), .int(position), .text(pet.name), .text(pet.petType.rawValue), .text(payload)]
                )
            }
            setState("selected_pet_id", selectedPetId.uuidString)
            setState("pets_ready", "1")
        }
    }

    func loadTasks() -> [CustomCareTask]? {
        guard state("tasks_ready") == "1" else { return nil }
        return rows("SELECT payload FROM care_tasks ORDER BY position ASC").compactMap { decode($0, as: CustomCareTask.self) }
    }

    func saveTasks(_ tasks: [CustomCareTask]) {
        transaction {
            execute("DELETE FROM care_tasks;")
            for (position, task) in tasks.enumerated() {
                guard let payload = encode(task) else { continue }
                run(
                    "INSERT INTO care_tasks (id, position, pet_id, title, payload) VALUES (?, ?, ?, ?, ?);",
                    bindings: [.text(task.id.uuidString), .int(position), .text(task.petId.uuidString), .text(task.title), .text(payload)]
                )
            }
            setState("tasks_ready", "1")
        }
    }

    func loadHealth() -> (records: [HealthRecord], reminders: [String])? {
        guard state("health_ready") == "1" else { return nil }
        let records: [HealthRecord] = rows("SELECT payload FROM health_records ORDER BY position ASC").compactMap { decode($0, as: HealthRecord.self) }
        let reminders = rows("SELECT message FROM health_reminders ORDER BY position ASC")
        return (records, reminders)
    }

    func saveHealth(records: [HealthRecord], reminders: [String]) {
        transaction {
            execute("DELETE FROM health_records;")
            execute("DELETE FROM health_reminders;")
            for (position, record) in records.enumerated() {
                guard let payload = encode(record) else { continue }
                run(
                    "INSERT INTO health_records (id, position, pet_id, title, record_type, payload) VALUES (?, ?, ?, ?, ?, ?);",
                    bindings: [
                        .text(record.id.uuidString),
                        .int(position),
                        .text(record.petId?.uuidString),
                        .text(record.title),
                        .text(record.recordType.rawValue),
                        .text(payload)
                    ]
                )
            }
            for (position, message) in reminders.enumerated() {
                run(
                    "INSERT INTO health_reminders (position, message) VALUES (?, ?);",
                    bindings: [.int(position), .text(message)]
                )
            }
            setState("health_ready", "1")
        }
    }

    func loadAssistantSessions() -> [AssistantConversation] {
        rows("SELECT payload FROM assistant_sessions ORDER BY position ASC").compactMap { decode($0, as: AssistantConversation.self) }
    }

    func saveAssistantSessions(_ sessions: [AssistantConversation]) {
        transaction {
            execute("DELETE FROM assistant_sessions;")
            for (position, session) in sessions.enumerated() {
                guard let payload = encode(session) else { continue }
                run(
                    "INSERT INTO assistant_sessions (id, position, pet_id, title, payload) VALUES (?, ?, ?, ?, ?);",
                    bindings: [
                        .text(session.id.uuidString),
                        .int(position),
                        .text(session.petId.uuidString),
                        .text(session.title),
                        .text(payload)
                    ]
                )
            }
        }
    }

    private func migrate() {
        execute("""
        CREATE TABLE IF NOT EXISTS app_state (
            key TEXT PRIMARY KEY,
            value TEXT NOT NULL
        );
        CREATE TABLE IF NOT EXISTS pets (
            id TEXT PRIMARY KEY,
            position INTEGER NOT NULL,
            name TEXT NOT NULL,
            species TEXT NOT NULL,
            payload TEXT NOT NULL
        );
        CREATE TABLE IF NOT EXISTS care_tasks (
            id TEXT PRIMARY KEY,
            position INTEGER NOT NULL,
            pet_id TEXT NOT NULL,
            title TEXT NOT NULL,
            payload TEXT NOT NULL
        );
        CREATE TABLE IF NOT EXISTS health_records (
            id TEXT PRIMARY KEY,
            position INTEGER NOT NULL,
            pet_id TEXT,
            title TEXT NOT NULL,
            record_type TEXT NOT NULL,
            payload TEXT NOT NULL
        );
        CREATE TABLE IF NOT EXISTS health_reminders (
            position INTEGER PRIMARY KEY,
            message TEXT NOT NULL
        );
        CREATE INDEX IF NOT EXISTS idx_care_tasks_pet ON care_tasks(pet_id);
        CREATE INDEX IF NOT EXISTS idx_health_records_pet ON health_records(pet_id);
        CREATE TABLE IF NOT EXISTS assistant_sessions (
            id TEXT PRIMARY KEY,
            position INTEGER NOT NULL,
            pet_id TEXT NOT NULL,
            title TEXT NOT NULL,
            payload TEXT NOT NULL
        );
        CREATE INDEX IF NOT EXISTS idx_assistant_sessions_pet ON assistant_sessions(pet_id);
        CREATE TABLE IF NOT EXISTS foods (
            id TEXT PRIMARY KEY,
            position INTEGER NOT NULL,
            name TEXT NOT NULL,
            payload TEXT NOT NULL
        );
        CREATE TABLE IF NOT EXISTS feedings (
            id TEXT PRIMARY KEY,
            position INTEGER NOT NULL,
            pet_id TEXT,
            payload TEXT NOT NULL
        );
        CREATE TABLE IF NOT EXISTS weight_logs (
            id TEXT PRIMARY KEY,
            position INTEGER NOT NULL,
            pet_id TEXT,
            payload TEXT NOT NULL
        );
        CREATE TABLE IF NOT EXISTS behavior_logs (
            id TEXT PRIMARY KEY,
            position INTEGER NOT NULL,
            pet_id TEXT,
            kind TEXT NOT NULL,
            payload TEXT NOT NULL
        );
        CREATE INDEX IF NOT EXISTS idx_feedings_pet ON feedings(pet_id);
        CREATE INDEX IF NOT EXISTS idx_weight_logs_pet ON weight_logs(pet_id);
        CREATE INDEX IF NOT EXISTS idx_behavior_logs_pet ON behavior_logs(pet_id);
        CREATE TABLE IF NOT EXISTS task_templates (
            id TEXT PRIMARY KEY,
            position INTEGER NOT NULL,
            title TEXT NOT NULL,
            payload TEXT NOT NULL
        );
        """)
    }

    func loadTaskTemplates() -> [CareTaskTemplate]? {
        guard state("task_templates_ready") == "1" else { return nil }
        return rows("SELECT payload FROM task_templates ORDER BY position ASC").compactMap { decode($0, as: CareTaskTemplate.self) }
    }

    func saveTaskTemplates(_ templates: [CareTaskTemplate]) {
        transaction {
            execute("DELETE FROM task_templates;")
            for (position, template) in templates.enumerated() {
                guard let payload = encode(template) else { continue }
                run(
                    "INSERT INTO task_templates (id, position, title, payload) VALUES (?, ?, ?, ?);",
                    bindings: [.text(template.id.uuidString), .int(position), .text(template.title), .text(payload)]
                )
            }
            setState("task_templates_ready", "1")
        }
    }

    func loadFoods() -> [FoodItem] {
        rows("SELECT payload FROM foods ORDER BY position ASC").compactMap { decode($0, as: FoodItem.self) }
    }

    func saveFoods(_ foods: [FoodItem]) {
        transaction {
            execute("DELETE FROM foods;")
            for (position, food) in foods.enumerated() {
                guard let payload = encode(food) else { continue }
                run(
                    "INSERT INTO foods (id, position, name, payload) VALUES (?, ?, ?, ?);",
                    bindings: [.text(food.id.uuidString), .int(position), .text(food.name), .text(payload)]
                )
            }
        }
    }

    func loadFeedings() -> [FeedingEntry] {
        rows("SELECT payload FROM feedings ORDER BY position ASC").compactMap { decode($0, as: FeedingEntry.self) }
    }

    func saveFeedings(_ entries: [FeedingEntry]) {
        transaction {
            execute("DELETE FROM feedings;")
            for (position, entry) in entries.enumerated() {
                guard let payload = encode(entry) else { continue }
                run(
                    "INSERT INTO feedings (id, position, pet_id, payload) VALUES (?, ?, ?, ?);",
                    bindings: [.text(entry.id.uuidString), .int(position), .text(entry.petId?.uuidString), .text(payload)]
                )
            }
        }
    }

    func loadWeights() -> [WeightEntry] {
        rows("SELECT payload FROM weight_logs ORDER BY position ASC").compactMap { decode($0, as: WeightEntry.self) }
    }

    func saveWeights(_ entries: [WeightEntry]) {
        transaction {
            execute("DELETE FROM weight_logs;")
            for (position, entry) in entries.enumerated() {
                guard let payload = encode(entry) else { continue }
                run(
                    "INSERT INTO weight_logs (id, position, pet_id, payload) VALUES (?, ?, ?, ?);",
                    bindings: [.text(entry.id.uuidString), .int(position), .text(entry.petId?.uuidString), .text(payload)]
                )
            }
        }
    }

    func loadBehaviors() -> [BehaviorEntry] {
        rows("SELECT payload FROM behavior_logs ORDER BY position ASC").compactMap { decode($0, as: BehaviorEntry.self) }
    }

    func saveBehaviors(_ entries: [BehaviorEntry]) {
        transaction {
            execute("DELETE FROM behavior_logs;")
            for (position, entry) in entries.enumerated() {
                guard let payload = encode(entry) else { continue }
                run(
                    "INSERT INTO behavior_logs (id, position, pet_id, kind, payload) VALUES (?, ?, ?, ?, ?);",
                    bindings: [
                        .text(entry.id.uuidString),
                        .int(position),
                        .text(entry.petId?.uuidString),
                        .text(entry.kind.rawValue),
                        .text(payload)
                    ]
                )
            }
        }
    }

    private func importLegacyJSONIfNeeded(in directory: URL) {
        if state("pets_ready") != "1",
           let roster = json(PetRoster.self, at: directory.appendingPathComponent("pets.json")) {
            savePets(roster.pets, selectedPetId: roster.selectedPetId)
        }
        if state("tasks_ready") != "1",
           let tasks = json([CustomCareTask].self, at: directory.appendingPathComponent("care-tasks.json")) {
            saveTasks(tasks)
        }
        if state("health_ready") != "1",
           let document = json(HealthDocument.self, at: directory.appendingPathComponent("health-records.json")) {
            saveHealth(records: document.records, reminders: document.reminders)
        }
    }

    private func json<T: Decodable>(_ type: T.Type, at url: URL) -> T? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? decoder.decode(type, from: data)
    }

    private func encode<T: Encodable>(_ value: T) -> String? {
        guard let data = try? encoder.encode(value) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    private func decode<T: Decodable>(_ payload: String, as type: T.Type) -> T? {
        guard let data = payload.data(using: .utf8) else { return nil }
        return try? decoder.decode(type, from: data)
    }

    private enum Binding {
        case text(String?)
        case int(Int)
    }

    private func transaction(_ body: () -> Void) {
        execute("BEGIN IMMEDIATE;")
        body()
        execute("COMMIT;")
    }

    func value(for key: String) -> String? {
        state(key)
    }

    func setValue(_ value: String, for key: String) {
        setState(key, value)
    }

    private func state(_ key: String) -> String? {
        rows("SELECT value FROM app_state WHERE key = ?;", bindings: [.text(key)]).first
    }

    private func setState(_ key: String, _ value: String) {
        run(
            "INSERT INTO app_state (key, value) VALUES (?, ?) ON CONFLICT(key) DO UPDATE SET value = excluded.value;",
            bindings: [.text(key), .text(value)]
        )
    }

    private func rows(_ sql: String, bindings: [Binding] = []) -> [String] {
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            logError(sql)
            return []
        }
        defer { sqlite3_finalize(statement) }
        bind(bindings, to: statement)
        var values: [String] = []
        while sqlite3_step(statement) == SQLITE_ROW {
            if let text = sqlite3_column_text(statement, 0) {
                values.append(String(cString: text))
            }
        }
        return values
    }

    private func run(_ sql: String, bindings: [Binding]) {
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            logError(sql)
            return
        }
        defer { sqlite3_finalize(statement) }
        bind(bindings, to: statement)
        if sqlite3_step(statement) != SQLITE_DONE {
            logError(sql)
        }
    }

    private func bind(_ bindings: [Binding], to statement: OpaquePointer?) {
        for (offset, binding) in bindings.enumerated() {
            let index = Int32(offset + 1)
            switch binding {
            case .text(let value):
                if let value {
                    value.withCString { cString in
                        sqlite3_bind_text(statement, index, cString, -1, sqliteTransient)
                    }
                } else {
                    sqlite3_bind_null(statement, index)
                }
            case .int(let value):
                sqlite3_bind_int(statement, index, Int32(value))
            }
        }
    }

    private func execute(_ sql: String) {
        var error: UnsafeMutablePointer<CChar>?
        if sqlite3_exec(db, sql, nil, nil, &error) != SQLITE_OK {
            if let error {
                logger.error("SQLite error: \(String(cString: error), privacy: .public)")
                sqlite3_free(error)
            }
        }
    }

    private func logError(_ sql: String) {
        if let message = sqlite3_errmsg(db) {
            logger.error("SQLite statement failed: \(String(cString: message), privacy: .public)")
        }
        logger.debug("SQL: \(sql, privacy: .public)")
    }
}

private struct PetRoster: Codable {
    var pets: [PetProfile]
    var selectedPetId: UUID
}

private struct HealthDocument: Codable {
    var records: [HealthRecord]
    var reminders: [String]
}
