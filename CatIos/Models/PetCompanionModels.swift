//
//  PetCompanionModels.swift
//  CatIos
//

import Foundation
import SwiftUI

// MARK: - Feeding Models
enum MealType: String, CaseIterable, Identifiable, Codable {
    case breakfast = "Breakfast"
    case lunch = "Lunch"
    case dinner = "Dinner"
    case snack = "Snacks / Treats"

    var id: String { rawValue }
    var icon: String {
        switch self {
        case .breakfast: return "sun.max.fill"
        case .lunch: return "sun.haze.fill"
        case .dinner: return "moon.stars.fill"
        case .snack: return "fish.fill"
        }
    }
}

enum FoodCategory: String, CaseIterable, Identifiable, Codable {
    case wet = "Wet Food"
    case dry = "Dry Food"
    case treat = "Treat"
    case raw = "Raw Food"

    var id: String { rawValue }
}

struct FeedingItem: Identifiable, Codable {
    var id: UUID = UUID()
    var time: String
    var mealType: MealType
    var foodCategory: FoodCategory
    var brand: String
    var portionGrams: Int
    var calories: Int?
    var isCompleted: Bool
    var dateLabel: String
}

// MARK: - Water Models
struct WaterLogEntry: Identifiable, Codable {
    var id: UUID = UUID()
    var time: String
    var type: String
    var amountMl: Int?
    var icon: String
}

// MARK: - Bathroom Models
enum BathroomEventType: String, CaseIterable, Identifiable, Codable {
    case pee = "Pee ✅"
    case poop = "Poop ✅"
    case cleaning = "Cleaning"
    case replacement = "Replacement"

    var id: String { rawValue }
    var icon: String {
        switch self {
        case .pee: return "drop.fill"
        case .poop: return "sparkles"
        case .cleaning: return "trash.fill"
        case .replacement: return "arrow.3.circlepath"
        }
    }
}

struct BathroomLogEntry: Identifiable, Codable {
    var id: UUID = UUID()
    var timeOfDay: String
    var timeString: String
    var eventType: BathroomEventType
    var notes: String?
}

// MARK: - Health Models
enum HealthRecordType: String, CaseIterable, Identifiable, Codable {
    case vaccination = "Vaccination"
    case medicine = "Medicine"
    case vetVisit = "Vet Visit"
    case temperature = "Temperature"
    case fleaTick = "Flea / Tick Treatment"
    case dental = "Dental Care"

    var id: String { rawValue }
    var icon: String {
        switch self {
        case .vaccination: return "syringe.fill"
        case .medicine: return "pill.fill"
        case .vetVisit: return "cross.case.fill"
        case .temperature: return "thermometer"
        case .fleaTick: return "shield.checkerboard"
        case .dental: return "mouth.fill"
        }
    }
}

struct HealthRecord: Identifiable, Codable {
    var id: UUID = UUID()
    var petId: UUID?
    var dateText: String
    var title: String
    var recordType: HealthRecordType
    var notes: String
    var doctorOrLocation: String?
    var upcomingDaysRemaining: Int?
    var date: Date?
    var nextDueDate: Date?
    var vaccineName: String?
    var isReminderSet: Bool?
    var frequency: TaskFrequency = .yearly
    var customInterval: Int = 1
    var customUnit: FrequencyUnit = .day
    var selectedDays: Set<Int> = [2, 3, 4, 5, 6]
}

// MARK: - Activity & Sleep Models
struct ActivitySummary: Codable {
    var sleepHours: Double
    var playMinutes: Int
    var exerciseMinutes: Int
    var energyLevel: String
}

// MARK: - Grooming Models
enum GroomingType: String, CaseIterable, Identifiable, Codable {
    case bath = "Bath"
    case brushing = "Brushing"
    case nailTrimming = "Nail Trimming"
    case earCleaning = "Ear Cleaning"
    case teethBrushing = "Teeth Brushing"

    var id: String { rawValue }
    var icon: String {
        switch self {
        case .bath: return "shower.fill"
        case .brushing: return "comb.fill"
        case .nailTrimming: return "scissors"
        case .earCleaning: return "ear.fill"
        case .teethBrushing: return "sparkles"
        }
    }
}

struct GroomingEntry: Identifiable, Codable {
    var id: UUID = UUID()
    var type: GroomingType
    var lastDoneDate: String
    var nextDueDateText: String
    var statusText: String
}

// MARK: - Behavior Models
enum PetMoodState: String, CaseIterable, Identifiable, Codable {
    case happy = "Happy"
    case normal = "Normal"
    case stressed = "Stressed"
    case angry = "Angry"

    var id: String { rawValue }
    var emoji: String {
        switch self {
        case .happy: return "😺"
        case .normal: return "🙂"
        case .stressed: return "😿"
        case .angry: return "😾"
        }
    }
}

struct BehaviorLogEntry: Identifiable, Codable {
    var id: UUID = UUID()
    var timeText: String
    var mood: PetMoodState
    var behaviorFlags: [String]
    var notes: String
}

struct PhotoMemory: Identifiable, Codable {
    var id: UUID = UUID()
    var title: String
    var dateText: String
    var emojiAvatar: String
    var note: String
}

// MARK: - Vet Profile
struct VetProfile: Codable {
    var clinicName: String
    var doctorName: String
    var phone: String
    var address: String
    var microchipId: String
    var allergies: [String]
    var previousIllnesses: [String]
    var documentNames: [String]
}
