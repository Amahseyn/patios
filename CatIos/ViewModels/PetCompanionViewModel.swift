//
//  CatCompanionViewModel.swift
//  CatIos
//

import Foundation
import SwiftUI
import Combine

class PetCompanionViewModel: ObservableObject {
    @Published var careScore: Int = 87

    @Published var feedingHistory: [FeedingItem] = [
        FeedingItem(time: "08:00", mealType: .breakfast, foodCategory: .wet, brand: "Royal Canin Ultra Soft", portionGrams: 100, calories: 95, isCompleted: true, dateLabel: "Today"),
        FeedingItem(time: "19:00", mealType: .dinner, foodCategory: .dry, brand: "Hill's Science Diet Adult", portionGrams: 50, calories: 180, isCompleted: false, dateLabel: "Today")
    ]

    @Published var feedingSmartReminders: [String] = [
        "Your pet usually eats around 7 PM.",
        "Dinner reminder in 30 minutes."
    ]

    @Published var waterLogs: [WaterLogEntry] = [
        WaterLogEntry(time: "08:30", type: "Water Bowl Refill", amountMl: 250, icon: "cup.and.saucer.fill"),
        WaterLogEntry(time: "14:00", type: "Water Fountain Refill", amountMl: 500, icon: "drop.fill")
    ]
    @Published var waterInsights: [String] = [
        "Luna drank less water than usual this week.",
        "Consider checking the water bowl."
    ]

    @Published var bathroomLogs: [BathroomLogEntry] = [
        BathroomLogEntry(timeOfDay: "Morning", timeString: "07:45", eventType: .pee, notes: "Normal urine amount"),
        BathroomLogEntry(timeOfDay: "Afternoon", timeString: "14:15", eventType: .poop, notes: "Healthy stool consistency")
    ]
    @Published var bathroomInsights: [String] = [
        "Bathroom frequency changed compared to last week (2 visits tracked today)."
    ]

    @Published var healthTimeline: [HealthRecord] = [
        HealthRecord(petId: PetProfile.mockLuna.id, dateText: "August 10", title: "Vaccination", recordType: .vaccination, notes: "Rabies & DHPP booster", doctorOrLocation: "Dr. Smith - City Vet Clinic", upcomingDaysRemaining: 8, frequency: .yearly, customInterval: 1),
        HealthRecord(petId: PetProfile.mockMilo.id, dateText: "August 20", title: "Dental Cleaning", recordType: .dental, notes: "Routine plaque check & scaling", doctorOrLocation: "City Vet Clinic", upcomingDaysRemaining: 18, frequency: .yearly, customInterval: 1),
        HealthRecord(petId: PetProfile.mockLuna.id, dateText: "July 15", title: "Flea & Tick Treatment", recordType: .fleaTick, notes: "Spot-on solution applied", doctorOrLocation: "Home", upcomingDaysRemaining: nil, frequency: .monthly, customInterval: 1)
    ]
    @Published var healthReminders: [String] = [
        "Vaccination due in 8 days."
    ]

    @Published var activitySummary: ActivitySummary = ActivitySummary(
        sleepHours: 15.0,
        playMinutes: 30,
        exerciseMinutes: 20,
        energyLevel: "High"
    )

    @Published var groomingItems: [GroomingEntry] = [
        GroomingEntry(type: .brushing, lastDoneDate: "3 days ago", nextDueDateText: "In 3 days", statusText: "Next brushing recommended in 3 days"),
        GroomingEntry(type: .bath, lastDoneDate: "1 month ago", nextDueDateText: "Tomorrow", statusText: "Bath scheduled tomorrow"),
        GroomingEntry(type: .nailTrimming, lastDoneDate: "1 week ago", nextDueDateText: "In 7 days", statusText: "Nail trim upcoming"),
        GroomingEntry(type: .earCleaning, lastDoneDate: "2 weeks ago", nextDueDateText: "Completed", statusText: "Ear check clean")
    ]

    @Published var currentMood: PetMoodState = .happy
    @Published var behaviorLogs: [BehaviorLogEntry] = [
        BehaviorLogEntry(timeText: "Today, 10:30 AM", mood: .happy, behaviorFlags: ["Purring", "Sunbathing"], notes: "No unusual behavior detected")
    ]

    @Published var photoMemories: [PhotoMemory] = [
        PhotoMemory(title: "First Day Home", dateText: "Jan 12, 2026", emojiAvatar: "🐱", note: "Exploring the living room rug"),
        PhotoMemory(title: "First Birthday Party", dateText: "May 4, 2026", emojiAvatar: "🎉", note: "Enjoyed tuna birthday treat cake")
    ]

    @Published var vetProfile: VetProfile = VetProfile(
        clinicName: "Happy Paws Veterinary Center",
        doctorName: "Dr. Sarah Jenkins, DVM",
        phone: "+1 (555) 019-2834",
        address: "742 Evergreen Terrace, San Francisco CA",
        microchipId: "985141002938471",
        allergies: ["Chicken byproduct", "Dust mites"],
        previousIllnesses: ["Mild upper respiratory infection (2025)"],
        documentNames: ["Vaccination_Certificate_2025.pdf", "Microchip_Registration.pdf", "Bloodwork_Report_May.pdf"]
    )

    func toggleFeedingCompletion(_ item: FeedingItem) {
        if let idx = feedingHistory.firstIndex(where: { $0.id == item.id }) {
            feedingHistory[idx].isCompleted.toggle()
        }
    }

    func addFeedingLog(meal: MealType, category: FoodCategory, brand: String, portion: Int) {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        let timeStr = formatter.string(from: Date())

        let newEntry = FeedingItem(
            time: timeStr,
            mealType: meal,
            foodCategory: category,
            brand: brand.isEmpty ? "Premium Pet Food" : brand,
            portionGrams: portion,
            calories: portion * 2,
            isCompleted: true,
            dateLabel: "Today"
        )
        feedingHistory.insert(newEntry, at: 0)
    }

    func logWaterRefill(type: String) {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        let timeStr = formatter.string(from: Date())

        let newLog = WaterLogEntry(time: timeStr, type: type, amountMl: 250, icon: "drop.fill")
        waterLogs.insert(newLog, at: 0)
    }

    func logBathroomEvent(type: BathroomEventType) {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        let timeStr = formatter.string(from: Date())

        let newEntry = BathroomLogEntry(timeOfDay: "Today", timeString: timeStr, eventType: type, notes: "Logged by owner")
        bathroomLogs.insert(newEntry, at: 0)
    }

    func addBehaviorLog(mood: PetMoodState, flags: [String], notes: String) {
        let newEntry = BehaviorLogEntry(timeText: "Just now", mood: mood, behaviorFlags: flags, notes: notes.isEmpty ? "Normal routine" : notes)
        behaviorLogs.insert(newEntry, at: 0)
        currentMood = mood
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
        let df = DateFormatter()
        df.dateStyle = .medium
        let dateStr = df.string(from: date)

        var daysRemaining: Int? = nil
        if let dueDate = nextDueDate {
            let components = Calendar.current.dateComponents([.day], from: Date(), to: dueDate)
            daysRemaining = max(0, components.day ?? 0)
        }

        let recordTitle = (recordType == .vaccination && !(vaccineName ?? "").isEmpty)
            ? "Vaccination: \(vaccineName!)"
            : (title.isEmpty ? recordType.rawValue : title)

        let newRecord = HealthRecord(
            petId: petId,
            dateText: dateStr,
            title: recordTitle,
            recordType: recordType,
            notes: notes.isEmpty ? "Routine health check" : notes,
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

        healthTimeline.insert(newRecord, at: 0)

        if isReminderSet, let days = daysRemaining {
            healthReminders.insert("\(recordTitle) scheduled in \(days) day(s).", at: 0)
        }

        if isReminderSet {
            HealthNotificationManager.shared.scheduleReminders(for: newRecord)
        }
    }

    func updateHealthRecord(_ record: HealthRecord) {
        guard let idx = healthTimeline.firstIndex(where: { $0.id == record.id }) else { return }
        let oldRecord = healthTimeline[idx]
        
        if oldRecord.isReminderSet == true, record.isReminderSet == false {
            HealthNotificationManager.shared.cancelReminders(for: record.id)
            if let title = oldRecord.title.isEmpty ? nil : oldRecord.title {
                healthReminders.removeAll { $0.contains(title) }
            }
        }
        
        healthTimeline[idx] = record
        
        if record.isReminderSet == true {
            HealthNotificationManager.shared.scheduleReminders(for: record)
            if let days = record.upcomingDaysRemaining {
                let reminderText = "\(record.title) scheduled in \(days) day(s)."
                if !healthReminders.contains(where: { $0.contains(record.title) }) {
                    healthReminders.append(reminderText)
                }
            }
        }
    }

    func removeHealthRecord(_ record: HealthRecord) {
        if record.isReminderSet == true {
            HealthNotificationManager.shared.cancelReminders(for: record.id)
            if !record.title.isEmpty {
                healthReminders.removeAll { $0.contains(record.title) }
            }
        }
        healthTimeline.removeAll { $0.id == record.id }
    }
}
