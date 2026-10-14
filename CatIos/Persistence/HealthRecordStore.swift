//
//  HealthRecordStore.swift
//  CatIos
//

import Foundation
import Combine

@MainActor
final class HealthRecordStore: ObservableObject {
    static let shared = HealthRecordStore()

    @Published private(set) var records: [HealthRecord]
    @Published private(set) var reminders: [String]

    private let database: AppDatabase

    init(database: AppDatabase = .shared) {
        self.database = database
        if let saved = database.loadHealth() {
            records = saved.records
            reminders = saved.reminders
        } else {
            records = HealthRecordStore.sampleRecords
            reminders = ["Vaccination due in 8 days."]
            persist()
        }
    }

    func addHealthRecord(
        title: String,
        recordType: HealthRecordType,
        date: Date,
        nextDueDate: Date?,
        vaccineName: String?,
        notes: String,
        doctorOrLocation: String?,
        isReminderSet: Bool,
        petId: UUID? = nil,
        frequency: TaskFrequency = .yearly,
        customInterval: Int = 1,
        customUnit: FrequencyUnit = .day,
        selectedDays: Set<Int> = [2, 3, 4, 5, 6]
    ) {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        let dateText = formatter.string(from: date)

        var daysRemaining: Int?
        if let nextDueDate {
            let components = Calendar.current.dateComponents([.day], from: Date(), to: nextDueDate)
            daysRemaining = max(0, components.day ?? 0)
        }

        let recordTitle = (recordType == .vaccination && !(vaccineName ?? "").isEmpty)
            ? "Vaccination: \(vaccineName!)"
            : (title.isEmpty ? recordType.rawValue : title)

        let record = HealthRecord(
            petId: petId,
            dateText: dateText,
            title: recordTitle,
            recordType: recordType,
            notes: notes,
            doctorOrLocation: doctorOrLocation,
            upcomingDaysRemaining: daysRemaining,
            date: date,
            nextDueDate: nextDueDate,
            vaccineName: vaccineName,
            isReminderSet: isReminderSet,
            frequency: frequency,
            customInterval: customInterval,
            customUnit: customUnit,
            selectedDays: selectedDays
        )
        records.insert(record, at: 0)

        if isReminderSet, let daysRemaining {
            reminders.insert("\(recordTitle) scheduled in \(daysRemaining) day(s).", at: 0)
        }
        if isReminderSet {
            HealthNotificationManager.shared.scheduleReminders(for: record)
        }
        persist()
    }

    func updateHealthRecord(_ record: HealthRecord) {
        guard let index = records.firstIndex(where: { $0.id == record.id }) else { return }
        let previous = records[index]

        if previous.isReminderSet == true, record.isReminderSet == false {
            HealthNotificationManager.shared.cancelReminders(for: record.id)
            if !previous.title.isEmpty {
                reminders.removeAll { $0.contains(previous.title) }
            }
        }

        records[index] = record

        if record.isReminderSet == true {
            HealthNotificationManager.shared.scheduleReminders(for: record)
            if let days = record.upcomingDaysRemaining,
               !reminders.contains(where: { $0.contains(record.title) }) {
                reminders.append("\(record.title) scheduled in \(days) day(s).")
            }
        }
        persist()
    }

    func removeHealthRecord(_ record: HealthRecord) {
        if record.isReminderSet == true {
            HealthNotificationManager.shared.cancelReminders(for: record.id)
            if !record.title.isEmpty {
                reminders.removeAll { $0.contains(record.title) }
            }
        }
        records.removeAll { $0.id == record.id }
        persist()
    }

    func applyNotificationPreference() {
        let allowed = NotificationPreferences.isOn(NotificationPreferences.masterKey)
            && NotificationPreferences.isOn(NotificationPreferences.healthKey)
        for record in records {
            if allowed, record.isReminderSet == true {
                HealthNotificationManager.shared.scheduleReminders(for: record)
            } else {
                HealthNotificationManager.shared.cancelReminders(for: record.id)
            }
        }
    }

    func clearIfOnlySamplePets() {
        let sampleIds: Set<UUID> = [PetProfile.mockLuna.id, PetProfile.mockMilo.id, PetProfile.mockBuddy.id]
        let onlySamples = records.allSatisfy { record in
            guard let petId = record.petId else { return false }
            return sampleIds.contains(petId)
        }
        guard onlySamples else { return }
        for record in records {
            HealthNotificationManager.shared.cancelReminders(for: record.id)
        }
        records = []
        reminders = []
        persist()
    }

    func replaceFromRemote(_ records: [HealthRecord], reminders: [String]? = nil) {
        self.records = records
        if let reminders {
            self.reminders = reminders
        }
        persist()
    }

    func detachPet(_ petId: UUID) {
        let removed = records.filter { $0.petId == petId }
        for record in removed where record.isReminderSet == true {
            HealthNotificationManager.shared.cancelReminders(for: record.id)
            if !record.title.isEmpty {
                reminders.removeAll { $0.contains(record.title) }
            }
        }
        records.removeAll { $0.petId == petId }
        persist()
    }

    private func persist() {
        database.saveHealth(records: records, reminders: reminders)
        NotificationCenter.default.post(name: .householdDidChange, object: nil)
    }

    private static let sampleRecords: [HealthRecord] = [
        HealthRecord(petId: PetProfile.mockLuna.id, dateText: "August 10", title: "Vaccination", recordType: .vaccination, notes: "Rabies & DHPP booster", doctorOrLocation: "Dr. Smith - City Vet Clinic", upcomingDaysRemaining: 8, frequency: .yearly, customInterval: 1),
        HealthRecord(petId: PetProfile.mockMilo.id, dateText: "August 20", title: "Dental Cleaning", recordType: .dental, notes: "Routine plaque check & scaling", doctorOrLocation: "City Vet Clinic", upcomingDaysRemaining: 18, frequency: .yearly, customInterval: 1),
        HealthRecord(petId: PetProfile.mockLuna.id, dateText: "July 15", title: "Flea & Tick Treatment", recordType: .fleaTick, notes: "Spot-on solution applied", doctorOrLocation: "Home", upcomingDaysRemaining: nil, frequency: .monthly, customInterval: 1)
    ]
}
