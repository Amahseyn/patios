import Foundation
import XCTest
@testable import CatIos

@MainActor
final class AppDatabaseTests: XCTestCase {
    private var directory: URL!
    private var database: AppDatabase!

    override func setUp() {
        super.setUp()
        directory = FileManager.default.temporaryDirectory.appendingPathComponent("patios-tests-\(UUID().uuidString)", isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        database = AppDatabase(directory: directory)
    }

    override func tearDown() {
        database = nil
        try? FileManager.default.removeItem(at: directory)
        super.tearDown()
    }

    func testEmptyDatabaseHasNoHouseholdUntilSaved() {
        XCTAssertNil(database.loadPets())
        XCTAssertNil(database.loadTasks())
        XCTAssertNil(database.loadHealth())
    }

    func testPetsTasksAndHealthSurviveReload() {
        let pet = PetProfile.mockBuddy
        let task = CustomCareTask(
            id: UUID(),
            petId: APIMapping.allPetsId,
            title: "Evening kibble",
            timeText: "07:00 PM",
            frequency: .weekly,
            selectedDays: [2, 4, 6],
            isCompleted: false,
            alarmEnabled: true,
            emojiIcon: "🥣",
            completedForPetIds: [pet.id],
            startDate: Date(timeIntervalSince1970: 1_700_000_000),
            completedPetDateOffsets: [pet.id: 0]
        )
        let due = Date(timeIntervalSince1970: 1_800_000_000)
        let record = HealthRecord(
            id: UUID(),
            petId: pet.id,
            dateText: "August 10",
            title: "Rabies booster",
            recordType: .vaccination,
            notes: "No reaction",
            doctorOrLocation: "City Vet",
            upcomingDaysRemaining: 8,
            date: Date(timeIntervalSince1970: 1_750_000_000),
            nextDueDate: due,
            vaccineName: "Rabies",
            isReminderSet: true,
            frequency: .yearly,
            customInterval: 1,
            customUnit: .year,
            selectedDays: [2, 4]
        )

        database.savePets([pet], selectedPetId: pet.id)
        database.saveTasks([task])
        database.saveHealth(records: [record], reminders: ["Rabies booster scheduled in 8 day(s)."])

        let reloaded = AppDatabase(directory: directory)
        let pets = reloaded.loadPets()
        XCTAssertEqual(pets?.pets.map(\.id), [pet.id])
        XCTAssertEqual(pets?.selectedPetId, pet.id)
        XCTAssertEqual(pets?.pets.first?.petType, .dog)

        let tasks = reloaded.loadTasks()
        XCTAssertEqual(tasks?.first?.id, task.id)
        XCTAssertEqual(tasks?.first?.petId, APIMapping.allPetsId)
        XCTAssertEqual(tasks?.first?.completedPetDateOffsets[pet.id], 0)
        XCTAssertEqual(tasks?.first?.selectedDays, Set([2, 4, 6]))

        let health = reloaded.loadHealth()
        XCTAssertEqual(health?.records.first?.id, record.id)
        XCTAssertEqual(health?.records.first?.vaccineName, "Rabies")
        XCTAssertEqual(health?.records.first?.isReminderSet, true)
        XCTAssertEqual(health?.reminders, ["Rabies booster scheduled in 8 day(s)."])
    }

    func testReplacingTasksRemovesRowsThatWereDeletedLocally() {
        let keep = CustomCareTask(
            petId: PetProfile.mockLuna.id,
            title: "Keep",
            timeText: "08:00 AM",
            frequency: .daily,
            isCompleted: false,
            alarmEnabled: true,
            emojiIcon: "🍗",
            startDate: Date()
        )
        let drop = CustomCareTask(
            petId: PetProfile.mockLuna.id,
            title: "Drop",
            timeText: "09:00 AM",
            frequency: .daily,
            isCompleted: false,
            alarmEnabled: true,
            emojiIcon: "💧",
            startDate: Date()
        )
        database.saveTasks([keep, drop])
        database.saveTasks([keep])
        XCTAssertEqual(database.loadTasks()?.map(\.title), ["Keep"])
    }
}

@MainActor
final class IsolatedStoreTests: XCTestCase {
    func testCareTaskStoreReplaceFromRemoteWritesThroughIsolatedDatabase() {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent("patios-store-\(UUID().uuidString)", isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let database = AppDatabase(directory: directory)
        let store = CareTaskStore(database: database)
        let remote = CustomCareTask(
            id: UUID(),
            petId: PetProfile.mockMilo.id,
            title: "Insulin",
            timeText: "02:00 PM",
            frequency: .daily,
            isCompleted: false,
            alarmEnabled: true,
            emojiIcon: "💊",
            startDate: Date()
        )
        store.replaceFromRemote([remote])
        XCTAssertEqual(store.tasks.map(\.id), [remote.id])
        XCTAssertEqual(database.loadTasks()?.map(\.title), ["Insulin"])
    }

    func testHealthStoreReplaceFromRemoteKeepsRecordIdentity() {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent("patios-health-\(UUID().uuidString)", isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let database = AppDatabase(directory: directory)
        let store = HealthRecordStore(database: database)
        let record = HealthRecord(
            id: UUID(),
            petId: nil,
            dateText: "Today",
            title: "Household flea treatment",
            recordType: .fleaTick,
            notes: "All pets",
            doctorOrLocation: "Home",
            isReminderSet: false,
            frequency: .monthly
        )
        store.replaceFromRemote([record])
        XCTAssertEqual(store.records.first?.id, record.id)
        XCTAssertNil(store.records.first?.petId)
        XCTAssertEqual(database.loadHealth()?.records.first?.title, "Household flea treatment")
    }
}

@MainActor
final class HouseholdScenarioTests: XCTestCase {
    func testFullHouseholdSnapshotRoundTripsThroughMapping() {
        let pet = PetProfile.mockBuddy
        let task = CustomCareTask(
            id: UUID(),
            petId: APIMapping.allPetsId,
            title: "Shared meal",
            timeText: "08:00 AM",
            frequency: .weekly,
            selectedDays: [2, 4, 6],
            isCompleted: false,
            alarmEnabled: true,
            emojiIcon: "🍗",
            completedForPetIds: [pet.id],
            startDate: Date(timeIntervalSince1970: 1_700_000_100),
            completedDateOffset: nil,
            completedPetDateOffsets: [pet.id: 0]
        )
        let record = HealthRecord(
            id: UUID(),
            petId: pet.id,
            dateText: "August 10",
            title: "Rabies booster",
            recordType: .vaccination,
            notes: "No reaction",
            doctorOrLocation: "City Vet",
            upcomingDaysRemaining: 8,
            date: Date(timeIntervalSince1970: 1_750_000_100),
            nextDueDate: Date(timeIntervalSince1970: 1_800_000_100),
            vaccineName: "Rabies",
            isReminderSet: true,
            frequency: .yearly,
            customInterval: 1,
            customUnit: .year,
            selectedDays: [2, 4]
        )

        let snapshot = APISyncSnapshot(
            pets: [APIMapping.apiPet(from: pet)],
            tasks: [APIMapping.apiTask(from: task)],
            healthRecords: [APIMapping.apiHealth(from: record)]
        )

        XCTAssertEqual(snapshot.pets[0].id, pet.id)
        XCTAssertEqual(snapshot.pets[0].species, "Dog")
        XCTAssertNil(snapshot.tasks[0].petId)
        XCTAssertEqual(snapshot.tasks[0].completedPetDateOffsets[pet.id.uuidString], 0)
        XCTAssertTrue(snapshot.healthRecords[0].reminderEnabled)

        let restoredPet = APIMapping.pet(from: snapshot.pets[0], existing: pet)
        let restoredTask = APIMapping.task(from: snapshot.tasks[0])
        let restoredHealth = APIMapping.health(from: snapshot.healthRecords[0])

        XCTAssertEqual(restoredPet.id, pet.id)
        XCTAssertEqual(restoredPet.petType, .dog)
        XCTAssertEqual(restoredPet.todayMoodEmoji, pet.todayMoodEmoji)
        XCTAssertEqual(restoredTask.petId, APIMapping.allPetsId)
        XCTAssertEqual(restoredTask.id, task.id)
        XCTAssertEqual(restoredHealth.id, record.id)
        XCTAssertEqual(restoredHealth.petId, pet.id)
        XCTAssertEqual(restoredHealth.vaccineName, "Rabies")
    }

    func testCustomSpeciesMapsAsOtherAndLowWellnessNeedsAttention() {
        var other = PetProfile.mockLuna
        other.id = UUID()
        other.name = "Kiwi"
        other.petType = .other
        other.customPetTypeName = "Parrot"
        other.wellnessScore = 55
        other.needsAttention = true

        let restored = APIMapping.pet(from: APIMapping.apiPet(from: other))
        XCTAssertEqual(restored.petType, .other)
        XCTAssertEqual(restored.customPetTypeName, "Parrot")
        XCTAssertTrue(restored.needsAttention)
        XCTAssertEqual(restored.wellnessScore, 55)
        XCTAssertEqual(restored.todayMoodEmoji, other.todayMoodEmoji)
        XCTAssertEqual(restored.userRole, other.userRole)
        XCTAssertEqual(restored.memories.map(\.title), other.memories.map(\.title))
        XCTAssertEqual(restored.soundPatterns.map(\.description), other.soundPatterns.map(\.description))
    }
}

@MainActor
final class AssistantSessionStoreTests: XCTestCase {
    private var directory: URL!

    override func setUp() {
        super.setUp()
        directory = FileManager.default.temporaryDirectory.appendingPathComponent("patios-assistant-\(UUID().uuidString)", isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: directory)
        super.tearDown()
    }

    func testChatsStayInSeparateSessions() async {
        let store = AssistantSessionStore(database: AppDatabase(directory: directory))
        let petId = UUID()
        let meals = store.start(petId: petId, title: "Meals", pendingPrompt: "What should Luna eat tonight?")
        let mood = store.start(petId: petId, title: "Mood")

        XCTAssertEqual(store.availableTitle("New chat", petId: petId), "New chat")
        XCTAssertEqual(store.consumePendingPrompt(id: meals), "What should Luna eat tonight?")
        XCTAssertNil(store.consumePendingPrompt(id: meals))

        let error = await store.deliver(text: "What should Luna eat tonight?", conversationId: meals, localReply: "Keep the usual bowl.")
        XCTAssertNil(error)
        XCTAssertEqual(store.conversation(id: meals)?.messages.map(\.text), ["What should Luna eat tonight?", "Keep the usual bowl."])
        XCTAssertEqual(store.conversation(id: mood)?.messages.count, 0)

        let reloaded = AssistantSessionStore(database: AppDatabase(directory: directory))
        XCTAssertEqual(reloaded.conversation(id: meals)?.messages.map(\.isUser), [true, false])
        XCTAssertEqual(reloaded.conversation(id: mood)?.title, "Mood")
        XCTAssertEqual(reloaded.conversations.map(\.id).count, 2)
    }
}
