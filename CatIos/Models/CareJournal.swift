import Foundation

enum NutritionCategory: String, CaseIterable, Identifiable, Codable {
    case dry = "Dry food"
    case wet = "Wet food"
    case homemade = "Homemade"
    case treats = "Treats"
    case supplements = "Supplements"
    case other = "Other"

    var id: String { rawValue }
}

enum BehaviorKind: String, CaseIterable, Identifiable, Codable {
    case park = "Park visit"
    case walk = "Walk"
    case play = "Play"
    case training = "Training"
    case social = "Social"
    case grooming = "Grooming"
    case vet = "Vet visit"
    case travel = "Travel"
    case anxiety = "Anxiety"
    case aggression = "Aggression"
    case barking = "Barking"
    case meowing = "Meowing"
    case other = "Other"

    var id: String { rawValue }

    var symbol: String {
        switch self {
        case .park: return "tree"
        case .walk: return "figure.walk"
        case .play: return "tennisball"
        case .training: return "graduationcap"
        case .social: return "person.2"
        case .grooming: return "comb"
        case .vet: return "cross.case"
        case .travel: return "car"
        case .anxiety: return "waveform.path.ecg"
        case .aggression: return "exclamationmark.triangle"
        case .barking: return "speaker.wave.2"
        case .meowing: return "cat"
        case .other: return "pawprint"
        }
    }

    var colorHex: String {
        switch self {
        case .anxiety, .aggression, .barking, .meowing: return "#D4654A"
        case .vet: return "#3D7EC4"
        default: return "#D4922A"
        }
    }

    var isPositive: Bool {
        switch self {
        case .park, .walk, .play, .training, .social, .grooming: return true
        default: return false
        }
    }
}

struct FoodItem: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var petId: UUID?
    var name: String
    var brand: String = ""
    var productName: String = ""
    var category: NutritionCategory = .other
    var caloriesPer100g: Double?
    var protein: Double?
    var fat: Double?
    var fiber: Double?
    var notes: String = ""
    var isFavorite: Bool = false
}

struct FeedingEntry: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var petId: UUID?
    var foodId: UUID?
    var fedAt: Date
    var foodName: String
    var brand: String = ""
    var amountGrams: Double
    var calories: Double?
    var notes: String = ""

    var amountKilograms: Double { amountGrams / 1000 }
}

struct WeightEntry: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var petId: UUID?
    var weight: Double
    var unit: String
    var loggedAt: Date
    var notes: String = ""

    var kilograms: Double {
        unit == "lb" ? weight * 0.453592 : weight
    }
}

struct BehaviorEntry: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var petId: UUID?
    var kind: BehaviorKind
    var title: String
    var occurredAt: Date
    var durationMinutes: Int
    var notes: String = ""
    var mood: String = ""
    var severity: Int = 1
    var location: String = ""
    var icon: String
    var colorHex: String
}
