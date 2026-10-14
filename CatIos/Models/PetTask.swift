//
//  PetTask.swift
//  CatIos
//

import Foundation
import SwiftUI

enum PetTaskFrequency: String, CaseIterable, Identifiable, Codable {
    case daily = "Daily"
    case weekly = "Weekly"
    case monthly = "Monthly"
    case custom = "Custom"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .daily: return "Daily"
        case .weekly: return "Weekly"
        case .monthly: return "Monthly"
        case .custom: return "Custom Interval"
        }
    }
}

struct PetTask: Identifiable, Codable {
    var id: UUID = UUID()
    var petId: UUID
    var title: String
    var category: CareCategory
    var frequency: PetTaskFrequency
    var customIntervalDays: Int? = nil
    var timeText: String
    var isCompleted: Bool = false
    var isEnabled: Bool = true
    var emojiIcon: String
    var createdAt: Date = Date()
}

struct PetTaskSuggestion: Identifiable, Codable {
    let id: String
    let title: String
    let category: CareCategory
    let emoji: String
    let petType: PetType
}

extension PetTaskSuggestion {
    static let all: [PetTaskSuggestion] = [
        PetTaskSuggestion(id: "cat_water", title: "Change Water", category: .activities, emoji: "💧", petType: .cat),
        PetTaskSuggestion(id: "cat_feed", title: "Feed Cat", category: .feeding, emoji: "🐟", petType: .cat),
        PetTaskSuggestion(id: "cat_litter", title: "Clean Litter Box", category: .activities, emoji: "🚽", petType: .cat),
        PetTaskSuggestion(id: "cat_groom", title: "Groom Cat", category: .grooming, emoji: "🧼", petType: .cat),
        PetTaskSuggestion(id: "cat_play", title: "Play Time", category: .activities, emoji: "🎮", petType: .cat),
        PetTaskSuggestion(id: "cat_vet", title: "Vet Appointment", category: .health, emoji: "🩺", petType: .cat),
        PetTaskSuggestion(id: "cat_med", title: "Medication", category: .health, emoji: "💊", petType: .cat),
        PetTaskSuggestion(id: "cat_vax", title: "Vaccination", category: .health, emoji: "💉", petType: .cat),

        PetTaskSuggestion(id: "dog_water", title: "Change Water", category: .activities, emoji: "💧", petType: .dog),
        PetTaskSuggestion(id: "dog_feed", title: "Feed Dog", category: .feeding, emoji: "🦴", petType: .dog),
        PetTaskSuggestion(id: "dog_walk", title: "Walk Dog", category: .activities, emoji: "🦮", petType: .dog),
        PetTaskSuggestion(id: "dog_exercise", title: "Exercise", category: .activities, emoji: "🎾", petType: .dog),
        PetTaskSuggestion(id: "dog_groom", title: "Groom Dog", category: .grooming, emoji: "🧼", petType: .dog),
        PetTaskSuggestion(id: "dog_bath", title: "Bath", category: .grooming, emoji: "🛁", petType: .dog),
        PetTaskSuggestion(id: "dog_vet", title: "Vet Appointment", category: .health, emoji: "🩺", petType: .dog),
        PetTaskSuggestion(id: "dog_med", title: "Medication", category: .health, emoji: "💊", petType: .dog),
        PetTaskSuggestion(id: "dog_vax", title: "Vaccination", category: .health, emoji: "💉", petType: .dog),

        PetTaskSuggestion(id: "bird_feed", title: "Fresh Food", category: .feeding, emoji: "🌾", petType: .bird),
        PetTaskSuggestion(id: "bird_water", title: "Change Water", category: .activities, emoji: "💧", petType: .bird),
        PetTaskSuggestion(id: "bird_cage", title: "Refresh the Cage", category: .grooming, emoji: "🪺", petType: .bird),

        PetTaskSuggestion(id: "rabbit_hay", title: "Fresh Hay", category: .feeding, emoji: "🌾", petType: .rabbit),
        PetTaskSuggestion(id: "rabbit_water", title: "Change Water", category: .activities, emoji: "💧", petType: .rabbit),
        PetTaskSuggestion(id: "rabbit_habitat", title: "Refresh the Habitat", category: .grooming, emoji: "🪺", petType: .rabbit),

        PetTaskSuggestion(id: "horse_feed", title: "Feed", category: .feeding, emoji: "🌾", petType: .horse),
        PetTaskSuggestion(id: "horse_water", title: "Check Water", category: .activities, emoji: "💧", petType: .horse),
        PetTaskSuggestion(id: "horse_groom", title: "Groom", category: .grooming, emoji: "🧼", petType: .horse),

        PetTaskSuggestion(id: "fish_feed", title: "Feed", category: .feeding, emoji: "🌾", petType: .fish),
        PetTaskSuggestion(id: "fish_water", title: "Check the Water", category: .activities, emoji: "💧", petType: .fish),

        PetTaskSuggestion(id: "hamster_feed", title: "Fresh Food", category: .feeding, emoji: "🌾", petType: .hamster),
        PetTaskSuggestion(id: "hamster_water", title: "Change Water", category: .activities, emoji: "💧", petType: .hamster),
        PetTaskSuggestion(id: "hamster_habitat", title: "Refresh the Habitat", category: .grooming, emoji: "🪺", petType: .hamster),

        PetTaskSuggestion(id: "reptile_feed", title: "Feed", category: .feeding, emoji: "🌾", petType: .reptile),
        PetTaskSuggestion(id: "reptile_habitat", title: "Check Heat and Water", category: .activities, emoji: "💧", petType: .reptile),

        PetTaskSuggestion(id: "other_feed", title: "Feed", category: .feeding, emoji: "🌾", petType: .other),
        PetTaskSuggestion(id: "other_water", title: "Fresh Water", category: .activities, emoji: "💧", petType: .other),
        PetTaskSuggestion(id: "other_care", title: "Gentle Care", category: .grooming, emoji: "🐾", petType: .other)
    ]

    static func suggestions(for petType: PetType) -> [PetTaskSuggestion] {
        all.filter { $0.petType == petType }
    }
}
