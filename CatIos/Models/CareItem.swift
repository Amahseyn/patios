//
//  CareItem.swift
//  CatIos
//

import Foundation
import SwiftUI

enum CareCategory: String, CaseIterable, Identifiable, Codable {
    case feeding = "Feeding"
    case grooming = "Grooming"
    case health = "Health"
    case activities = "Activities"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .feeding: return "🐟"
        case .grooming: return "🧼"
        case .health: return "💊"
        case .activities: return "🎮"
        }
    }

    var sfSymbol: String {
        switch self {
        case .feeding: return "fork.knife"
        case .grooming: return "sparkles"
        case .health: return "cross.case.fill"
        case .activities: return "gamecontroller.fill"
        }
    }

    var themeColor: Color {
        switch self {
        case .feeding: return Color.orange
        case .grooming: return Color.teal
        case .health: return Color.pink
        case .activities: return Color.purple
        }
    }

    var subcategories: [String] {
        switch self {
        case .feeding:
            return ["Breakfast", "Lunch", "Dinner", "Treats", "Water refill"]
        case .grooming:
            return ["Bath", "Brushing", "Nail trimming", "Ear cleaning"]
        case .health:
            return ["Medication", "Vaccination", "Vet appointment"]
        case .activities:
            return ["Play time", "Exercise", "Training", "Walk"]
        }
    }
}

struct CareReminder: Identifiable {
    let id: UUID
    var title: String
    var category: CareCategory
    var subcategory: String
    var scheduledDate: Date
    var timeString: String
    var isCompleted: Bool
    var frequency: String
    var petId: UUID?

    init(id: UUID = UUID(), title: String, category: CareCategory, subcategory: String, scheduledDate: Date = Date(), timeString: String, isCompleted: Bool = false, frequency: String = "Daily", petId: UUID? = nil) {
        self.id = id
        self.title = title
        self.category = category
        self.subcategory = subcategory
        self.scheduledDate = scheduledDate
        self.timeString = timeString
        self.isCompleted = isCompleted
        self.frequency = frequency
        self.petId = petId
    }
}

struct AISuggestion: Identifiable {
    let id: UUID
    let title: String
    let message: String
    let category: CareCategory
    let actionTitle: String
    let icon: String

    init(id: UUID = UUID(), title: String, message: String, category: CareCategory, actionTitle: String, icon: String) {
        self.id = id
        self.title = title
        self.message = message
        self.category = category
        self.actionTitle = actionTitle
        self.icon = icon
    }
}

struct NotificationPreviewCard: Identifiable {
    let id: UUID
    let title: String
    let message: String
    let timeAgoText: String
    let category: CareCategory
    let icon: String

    init(id: UUID = UUID(), title: String, message: String, timeAgoText: String, category: CareCategory, icon: String) {
        self.id = id
        self.title = title
        self.message = message
        self.timeAgoText = timeAgoText
        self.category = category
        self.icon = icon
    }
}

struct WellnessScore {
    var petName: String
    var moodScore: Int
    var nutritionScore: Int
    var activityScore: Int
    var groomingScore: Int

    var overallScore: Int {
        Int(Double(moodScore + nutritionScore + activityScore + groomingScore) / 4.0)
    }
}
