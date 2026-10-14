import XCTest
@testable import CatIos

@MainActor
final class APIMappingTests: XCTestCase {
    func testUUIDSpeciesAndReminderSurviveRoundTrip() {
        let pet = PetProfile.mockBuddy
        let remotePet = APIMapping.apiPet(from: pet)
        XCTAssertEqual(remotePet.species, pet.petType.rawValue)
        let restoredPet = APIMapping.pet(from: remotePet, existing: pet)
        XCTAssertEqual(restoredPet.id, pet.id)
        XCTAssertEqual(restoredPet.petType, pet.petType)

        let taskId = UUID()
        let task = CustomCareTask(
            id: taskId,
            petId: APIMapping.allPetsId,
            title: "Evening kibble",
            timeText: "07:00 PM",
            frequency: .daily,
            isCompleted: false,
            alarmEnabled: true,
            emojiIcon: "🥣",
            startDate: Date()
        )
        let remoteTask = APIMapping.apiTask(from: task)
        XCTAssertEqual(remoteTask.id, taskId)
        XCTAssertNil(remoteTask.petId)
        XCTAssertEqual(APIMapping.task(from: remoteTask).id, taskId)
        XCTAssertEqual(APIMapping.task(from: remoteTask).petId, APIMapping.allPetsId)

        let recordId = UUID()
        let record = HealthRecord(
            id: recordId,
            petId: pet.id,
            dateText: "August 10",
            title: "Rabies booster",
            recordType: .vaccination,
            notes: "No reaction",
            doctorOrLocation: "City Vet",
            date: Date(),
            vaccineName: "Rabies",
            isReminderSet: true,
            frequency: .yearly
        )
        let remoteRecord = APIMapping.apiHealth(from: record)
        XCTAssertEqual(remoteRecord.id, recordId)
        XCTAssertTrue(remoteRecord.reminderEnabled)
        let restoredRecord = APIMapping.health(from: remoteRecord)
        XCTAssertEqual(restoredRecord.id, recordId)
        XCTAssertEqual(restoredRecord.isReminderSet, true)
        XCTAssertEqual(restoredRecord.recordType, .vaccination)
    }

    func testAllPetsSentinelMapsToNullPetId() throws {
        let task = CustomCareTask(
            id: UUID(),
            petId: APIMapping.allPetsId,
            title: "Evening kibble",
            timeText: "07:00 PM",
            frequency: .daily,
            isCompleted: false,
            alarmEnabled: true,
            emojiIcon: "🥣",
            startDate: Date()
        )
        let remote = APIMapping.apiTask(from: task)
        XCTAssertNil(remote.petId)

        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.dateEncodingStrategy = .iso8601
        let encoded = try encoder.encode(remote)
        let object = try XCTUnwrap(JSONSerialization.jsonObject(with: encoded) as? [String: Any])
        if let petField = object["pet_id"] {
            XCTAssertTrue(petField is NSNull)
        }

        var withNull = object
        withNull["pet_id"] = NSNull()
        let nulled = try JSONSerialization.data(withJSONObject: withNull)
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(APICareTask.self, from: nulled)
        XCTAssertNil(decoded.petId)
        XCTAssertEqual(APIMapping.task(from: decoded).petId, APIMapping.allPetsId)
    }

    func testPetRoundTripKeepsIdentityAndSpecies() {
        let pet = PetProfile.mockBuddy
        let remote = APIMapping.apiPet(from: pet)
        let restored = APIMapping.pet(from: remote, existing: pet)
        XCTAssertEqual(restored.id, pet.id)
        XCTAssertEqual(restored.name, "Buddy")
        XCTAssertEqual(restored.petType, .dog)
        XCTAssertEqual(restored.gender, .male)
        XCTAssertEqual(restored.age.years, 4)
        XCTAssertEqual(restored.avatarEmoji, "🐶")
        XCTAssertEqual(restored.vocal, pet.vocal)
    }

    func testHealthReminderAndDateFieldsSync() {
        let due = Date().addingTimeInterval(86_400)
        let record = HealthRecord(
            id: UUID(),
            petId: PetProfile.mockLuna.id,
            dateText: "August 10",
            title: "Rabies booster",
            recordType: .vaccination,
            notes: "No reaction",
            doctorOrLocation: "City Vet",
            upcomingDaysRemaining: 8,
            date: Date(),
            nextDueDate: due,
            vaccineName: "Rabies",
            isReminderSet: true,
            frequency: .yearly,
            customInterval: 1,
            customUnit: .year,
            selectedDays: [2, 4]
        )
        let remote = APIMapping.apiHealth(from: record)
        XCTAssertTrue(remote.reminderEnabled)
        XCTAssertEqual(remote.recordType, "Vaccination")
        let restored = APIMapping.health(from: remote)
        XCTAssertEqual(restored.vaccineName, "Rabies")
        XCTAssertEqual(restored.isReminderSet, true)
        XCTAssertEqual(restored.frequency, .yearly)
        XCTAssertEqual(restored.selectedDays, Set([2, 4]))
    }

    func testTaskCompletionOffsetsSurviveSync() {
        let luna = PetProfile.mockLuna.id
        let task = CustomCareTask(
            petId: APIMapping.allPetsId,
            title: "Shared meal",
            timeText: "08:00 AM",
            frequency: .weekly,
            selectedDays: [2, 4, 6],
            isCompleted: false,
            alarmEnabled: true,
            emojiIcon: "🍗",
            completedForPetIds: [luna],
            startDate: Date(),
            completedPetDateOffsets: [luna: 0]
        )
        let restored = APIMapping.task(from: APIMapping.apiTask(from: task))
        XCTAssertEqual(restored.selectedDays, Set([2, 4, 6]))
        XCTAssertEqual(restored.completedPetDateOffsets[luna], 0)
        XCTAssertEqual(restored.emojiIcon, "🍗")
    }
}

@MainActor
final class CareScheduleTests: XCTestCase {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }

    private func date(_ year: Int, _ month: Int, _ day: Int, hour: Int = 12) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        return calendar.date(from: components)!
    }

    func testDailyTaskOccursEveryDayAfterStart() {
        let start = date(2026, 9, 1)
        let task = CustomCareTask(
            petId: PetProfile.mockLuna.id,
            title: "Breakfast",
            timeText: "08:00 AM",
            frequency: .daily,
            isCompleted: false,
            alarmEnabled: true,
            emojiIcon: "🍗",
            startDate: start
        )
        XCTAssertTrue(CareSchedule.occurs(task, on: date(2026, 9, 1), calendar: calendar))
        XCTAssertTrue(CareSchedule.occurs(task, on: date(2026, 9, 22), calendar: calendar))
        XCTAssertFalse(CareSchedule.occurs(task, on: date(2026, 8, 31), calendar: calendar))
    }

    func testWeeklyTaskUsesSelectedWeekdays() {
        let start = date(2026, 9, 1)
        let task = CustomCareTask(
            petId: PetProfile.mockLuna.id,
            title: "Bath",
            timeText: "05:00 PM",
            frequency: .weekly,
            selectedDays: [3, 5],
            isCompleted: false,
            alarmEnabled: true,
            emojiIcon: "🛁",
            startDate: start
        )
        XCTAssertTrue(CareSchedule.occurs(task, on: date(2026, 9, 1), calendar: calendar))
        XCTAssertFalse(CareSchedule.occurs(task, on: date(2026, 9, 2), calendar: calendar))
        XCTAssertTrue(CareSchedule.occurs(task, on: date(2026, 9, 3), calendar: calendar))
    }

    func testCustomEveryTwoDays() {
        let start = date(2026, 9, 1)
        let task = CustomCareTask(
            petId: PetProfile.mockLuna.id,
            title: "Medicine",
            timeText: "02:00 PM",
            frequency: .custom,
            customInterval: 2,
            customUnit: .day,
            isCompleted: false,
            alarmEnabled: true,
            emojiIcon: "💊",
            startDate: start
        )
        XCTAssertTrue(CareSchedule.occurs(task, on: date(2026, 9, 1), calendar: calendar))
        XCTAssertFalse(CareSchedule.occurs(task, on: date(2026, 9, 2), calendar: calendar))
        XCTAssertTrue(CareSchedule.occurs(task, on: date(2026, 9, 3), calendar: calendar))
    }

    func testTimeTextParsesToMinutes() {
        XCTAssertEqual(CareSchedule.minutes(from: "08:00 AM", calendar: calendar), 8 * 60)
        XCTAssertEqual(CareSchedule.minutes(from: "02:00 PM", calendar: calendar), 14 * 60)
    }

    func testMonthlyAndYearlyMatchStartCalendarDay() {
        let start = date(2026, 9, 15)
        let monthly = CustomCareTask(
            petId: PetProfile.mockLuna.id,
            title: "Nail trim",
            timeText: "11:00 AM",
            frequency: .monthly,
            isCompleted: false,
            alarmEnabled: true,
            emojiIcon: "✂️",
            startDate: start
        )
        XCTAssertTrue(CareSchedule.occurs(monthly, on: date(2026, 9, 15), calendar: calendar))
        XCTAssertFalse(CareSchedule.occurs(monthly, on: date(2026, 9, 16), calendar: calendar))
        XCTAssertTrue(CareSchedule.occurs(monthly, on: date(2026, 10, 15), calendar: calendar))

        let yearly = CustomCareTask(
            petId: PetProfile.mockLuna.id,
            title: "Birthday exam",
            timeText: "10:00 AM",
            frequency: .yearly,
            isCompleted: false,
            alarmEnabled: true,
            emojiIcon: "🎂",
            startDate: start
        )
        XCTAssertTrue(CareSchedule.occurs(yearly, on: date(2027, 9, 15), calendar: calendar))
        XCTAssertFalse(CareSchedule.occurs(yearly, on: date(2027, 9, 16), calendar: calendar))
        XCTAssertFalse(CareSchedule.occurs(yearly, on: date(2027, 8, 15), calendar: calendar))
    }
}

@MainActor
final class CareAssistantReplyTests: XCTestCase {
    func testMoodQuestionMentionsPet() {
        let reply = CareAssistantReply.reply(for: "Is my pet happy?", petName: "Buddy", wellnessScore: 88)
        XCTAssertTrue(reply.contains("Buddy"))
        XCTAssertTrue(reply.contains("88"))
    }

    func testHealthQuestionPointsToHealthTab() {
        let reply = CareAssistantReply.reply(for: "When is the next vaccine?", petName: "Luna", wellnessScore: 92)
        XCTAssertTrue(reply.lowercased().contains("health"))
    }

    func testNightAndRoutinePromptsMentionPet() {
        let night = CareAssistantReply.reply(for: "Why does she cry at night?", petName: "Luna", wellnessScore: 90)
        XCTAssertTrue(night.contains("Luna"))
        let routine = CareAssistantReply.reply(for: "Build a schedule", petName: "Milo", wellnessScore: 80)
        XCTAssertTrue(routine.contains("Milo"))
        let fallback = CareAssistantReply.reply(for: "Hello", petName: "Buddy", wellnessScore: 88)
        XCTAssertTrue(fallback.contains("Buddy"))
        XCTAssertTrue(fallback.contains(CareInsights.disclaimer))
    }

    func testDiagnosisAskIsRefused() {
        let reply = CareAssistantReply.reply(for: "What disease is this and what medication dose should I give?", petName: "Milo", wellnessScore: 70)
        XCTAssertTrue(reply.contains("can’t diagnose"))
        XCTAssertTrue(reply.contains(CareInsights.disclaimer))
        XCTAssertFalse(reply.lowercased().contains("diabetes"))
    }
}
