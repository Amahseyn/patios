import Foundation

struct AssistantTurn: Identifiable, Codable, Equatable {
    var id: UUID
    var text: String
    var isUser: Bool
    var createdAt: Date
}

struct AssistantConversation: Identifiable, Codable, Equatable {
    var id: UUID
    var petId: UUID
    var title: String
    var messages: [AssistantTurn]
    var createdAt: Date
    var updatedAt: Date
    var synced: Bool
    var pendingPrompt: String?

    var preview: String {
        messages.last?.text ?? "No messages yet"
    }
}

enum AssistantTopic: String, CaseIterable, Identifiable {
    case meals = "Meals"
    case mood = "Mood"
    case health = "Health"
    case routine = "Routine"

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .meals: return "fork.knife"
        case .mood: return "face.smiling"
        case .health: return "heart.text.square"
        case .routine: return "calendar"
        }
    }

    func prompt(petName: String) -> String {
        switch self {
        case .meals: return "What should \(petName) eat tonight?"
        case .mood: return "How is \(petName) feeling?"
        case .health: return "Any health reminders for \(petName)?"
        case .routine: return "Help me plan \(petName)’s day."
        }
    }
}
