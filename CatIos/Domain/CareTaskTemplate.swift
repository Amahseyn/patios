import Foundation

struct CareTaskTemplate: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var title: String
    var emojiIcon: String = "🐾"
    var taskKind: CareTaskKind = .custom
    var timeText: String = "08:00 AM"
    var frequency: TaskFrequency = .daily
    var customInterval: Int = 1
    var customUnit: FrequencyUnit = .day
    var selectedDays: Set<Int> = [2, 3, 4, 5, 6]
    var alarmEnabled: Bool = true
    var appliesToAllPets: Bool = true
    var petIds: [UUID] = []

    var petScopeLabel: String {
        if appliesToAllPets { return "All pets" }
        if petIds.count == 1 { return "1 pet" }
        return "\(petIds.count) pets"
    }

    static func from(task: CustomCareTask) -> CareTaskTemplate {
        CareTaskTemplate(
            title: task.title,
            emojiIcon: task.emojiIcon,
            taskKind: task.taskKind,
            timeText: task.timeText,
            frequency: task.frequency,
            customInterval: task.customInterval,
            customUnit: task.customUnit,
            selectedDays: task.selectedDays,
            alarmEnabled: task.alarmEnabled,
            appliesToAllPets: task.petId == PetManager.allPetsId,
            petIds: task.petId == PetManager.allPetsId ? [] : [task.petId]
        )
    }

    func makeScheduledTasks(startDate: Date = Date()) -> [CustomCareTask] {
        let base = CustomCareTask(
            petId: PetManager.allPetsId,
            title: title,
            timeText: timeText,
            frequency: frequency,
            customInterval: customInterval,
            customUnit: customUnit,
            selectedDays: selectedDays,
            isCompleted: false,
            alarmEnabled: alarmEnabled,
            emojiIcon: emojiIcon,
            startDate: startDate,
            completedDateOffset: nil,
            completedPetDateOffsets: [:],
            taskKind: taskKind
        )

        if appliesToAllPets {
            return [base]
        }

        let targets = petIds
        guard !targets.isEmpty else { return [] }
        return targets.map { petId in
            var task = base
            task.id = UUID()
            task.petId = petId
            return task
        }
    }

    static var starters: [CareTaskTemplate] {
        [
            CareTaskTemplate(
                title: "Morning meal",
                emojiIcon: "🍗",
                taskKind: .feeding,
                timeText: "08:00 AM",
                frequency: .daily,
                appliesToAllPets: true
            ),
            CareTaskTemplate(
                title: "Fresh water",
                emojiIcon: "💧",
                timeText: "09:00 AM",
                frequency: .daily,
                appliesToAllPets: true
            ),
            CareTaskTemplate(
                title: "Evening walk",
                emojiIcon: "🚶",
                taskKind: .walking,
                timeText: "06:00 PM",
                frequency: .daily,
                appliesToAllPets: true
            ),
            CareTaskTemplate(
                title: "Medicine dose",
                emojiIcon: "💊",
                taskKind: .medication,
                timeText: "08:00 PM",
                frequency: .daily,
                appliesToAllPets: true
            )
        ]
    }
}
