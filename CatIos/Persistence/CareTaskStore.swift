

import Foundation
import Combine

@MainActor
final class CareTaskStore: ObservableObject {
    static let shared = CareTaskStore()

    @Published var tasks: [CustomCareTask] {
        didSet { persist() }
    }

    @Published var templates: [CareTaskTemplate] {
        didSet { persistTemplates() }
    }

    private let database: AppDatabase
    private var isReady = false

    init(database: AppDatabase = .shared) {
        self.database = database
        if let saved = database.loadTasks() {
            tasks = saved
        } else {
            tasks = Self.sampleTasks
        }
        if let savedTemplates = database.loadTaskTemplates() {
            templates = savedTemplates
        } else {
            templates = CareTaskTemplate.starters
        }
        isReady = true
        if database.loadTasks() == nil {
            persist()
        }
        if database.loadTaskTemplates() == nil {
            persistTemplates()
        }
    }

    func replaceFromRemote(_ tasks: [CustomCareTask], templates: [CareTaskTemplate]? = nil) {
        self.tasks = tasks
        if let templates {
            self.templates = templates
        }
    }

    func addTemplate(from task: CustomCareTask) {
        let template = CareTaskTemplate.from(task: task)
        if let index = templates.firstIndex(where: { $0.title.caseInsensitiveCompare(template.title) == .orderedSame }) {
            templates[index] = template
        } else {
            templates.insert(template, at: 0)
        }
    }

    func applyTemplate(_ template: CareTaskTemplate) -> [CustomCareTask] {
        template.makeScheduledTasks()
    }

    func detachPet(_ petId: UUID) {
        var next = tasks.filter { $0.petId != petId }
        for index in next.indices {
            next[index].completedForPetIds.removeAll { $0 == petId }
            next[index].completedPetDateOffsets.removeValue(forKey: petId)
        }
        tasks = next
    }

    private func persist() {
        guard isReady else { return }
        database.saveTasks(tasks)
        NotificationCenter.default.post(name: .householdDidChange, object: nil)
        CareReminderScheduler.shared.reschedule(tasks: tasks)
    }

    private func persistTemplates() {
        guard isReady else { return }
        database.saveTaskTemplates(templates)
        NotificationCenter.default.post(name: .householdDidChange, object: nil)
    }

    func replaceWithStarter(petId: UUID) {
        let start = Date()
        tasks = [
            CustomCareTask(petId: petId, title: "Morning meal", timeText: "08:00 AM", frequency: .daily, isCompleted: false, alarmEnabled: true, emojiIcon: "🍽️", startDate: start),
            CustomCareTask(petId: petId, title: "Fresh water", timeText: "09:00 AM", frequency: .daily, isCompleted: false, alarmEnabled: true, emojiIcon: "💧", startDate: start),
            CustomCareTask(petId: petId, title: "Evening play", timeText: "06:30 PM", frequency: .daily, isCompleted: false, alarmEnabled: true, emojiIcon: "🎾", startDate: start)
        ]
    }

    static var sampleTasks: [CustomCareTask] {
        [
            CustomCareTask(petId: PetProfile.mockLuna.id, title: "Morning Wet Salmon Pouch", timeText: "08:00 AM", frequency: .daily, isCompleted: true, alarmEnabled: true, emojiIcon: "🍗", startDate: Date(), completedDateOffset: 0, taskKind: .feeding),
            CustomCareTask(petId: PetProfile.mockLuna.id, title: "Fresh Water Fountain Refill", timeText: "09:00 AM", frequency: .daily, isCompleted: true, alarmEnabled: true, emojiIcon: "💧", startDate: Date(), completedDateOffset: 0),
            CustomCareTask(petId: PetProfile.mockMilo.id, title: "Litter Box Scoop & Clean", timeText: "08:30 AM", frequency: .daily, isCompleted: true, alarmEnabled: true, emojiIcon: "🚽", startDate: Date(), completedDateOffset: 0),
            CustomCareTask(petId: PetProfile.mockMilo.id, title: "Afternoon Insulin / Medicine", timeText: "02:00 PM", frequency: .daily, isCompleted: false, alarmEnabled: true, emojiIcon: "💊", startDate: Date(), completedDateOffset: nil, taskKind: .medication),
            CustomCareTask(petId: PetManager.allPetsId, title: "Evening Crunchy Kibble", timeText: "07:00 PM", frequency: .daily, isCompleted: false, alarmEnabled: true, emojiIcon: "🥣", completedForPetIds: [PetProfile.mockLuna.id], startDate: Date(), completedPetDateOffsets: [PetProfile.mockLuna.id: 0], taskKind: .feeding),
            CustomCareTask(petId: PetManager.allPetsId, title: "Vaccination Booster", timeText: "10:00 AM", frequency: .monthly, customInterval: 1, isCompleted: false, alarmEnabled: true, emojiIcon: "💉", startDate: Date(), completedDateOffset: nil, completedPetDateOffsets: [:], taskKind: .vet),
            CustomCareTask(petId: PetProfile.mockLuna.id, title: "Warm Sponge Bath & Brush", timeText: "05:00 PM", frequency: .weekly, selectedDays: [2, 4, 6], isCompleted: false, alarmEnabled: true, emojiIcon: "🛁", startDate: Date(), completedDateOffset: nil, taskKind: .grooming),
            CustomCareTask(petId: PetProfile.mockBuddy.id, title: "Evening walk", timeText: "06:00 PM", frequency: .daily, isCompleted: false, alarmEnabled: true, emojiIcon: "🦮", startDate: Date(), taskKind: .walking),
            CustomCareTask(petId: PetProfile.mockBuddy.id, title: "Weigh Buddy", timeText: "09:00 AM", frequency: .weekly, selectedDays: [1], isCompleted: false, alarmEnabled: true, emojiIcon: "⚖️", startDate: Date(), taskKind: .weight),
            CustomCareTask(petId: PetProfile.mockMilo.id, title: "Feather Wand Play Session", timeText: "06:30 PM", frequency: .daily, isCompleted: false, alarmEnabled: true, emojiIcon: "🪶", startDate: Date(), completedDateOffset: nil, taskKind: .training)
        ]
    }
}
