import Foundation

enum AppConfig {
    static let apiBaseURLKey = "apiBaseURL"
    static let defaultAPIBaseURL = "http://127.0.0.1:8000/api/v1"

    static var apiBaseURL: URL {
        let stored = UserDefaults.standard.string(forKey: apiBaseURLKey)?.trimmingCharacters(in: .whitespacesAndNewlines)
        let raw: String
        if let stored, !stored.isEmpty {
            raw = stored
        } else {
            raw = resolvedDefaultAPIBaseURL
        }
        return URL(string: raw) ?? URL(string: defaultAPIBaseURL)!
    }

    private static var resolvedDefaultAPIBaseURL: String {
        #if DEBUG
        #if targetEnvironment(simulator)
        return defaultAPIBaseURL
        #else
        return DevAuthConfig.apiBaseURL
        #endif
        #else
        return defaultAPIBaseURL
        #endif
    }

    #if DEBUG
    static func applyDevAPIBaseURLIfNeeded() {
        #if !targetEnvironment(simulator)
        let existing = UserDefaults.standard.string(forKey: apiBaseURLKey)?.trimmingCharacters(in: .whitespacesAndNewlines)
        let usesLocalhost = existing?.contains("127.0.0.1") == true || existing?.contains("localhost") == true
        guard existing?.isEmpty != false || usesLocalhost else { return }
        UserDefaults.standard.set(DevAuthConfig.apiBaseURL, forKey: apiBaseURLKey)
        #endif
    }
    #endif
}

struct APIErrorBody: Codable {
    struct Detail: Codable {
        let code: String
        let message: String
    }

    let error: Detail
}

enum APIError: LocalizedError {
    case message(String)
    case unauthorized
    case unreachable
    case conflict

    var errorDescription: String? {
        switch self {
        case .message(let text): return text
        case .unauthorized: return "Sign in to sync this household."
        case .unreachable: return "Can’t reach Pet Care. Check the server address."
        case .conflict: return "This household changed on another device. Refreshing."
        }
    }
}

struct APITokenPair: Codable {
    var accessToken: String
    var refreshToken: String
    var tokenType: String
}

struct APIUser: Codable, Equatable {
    var id: UUID
    var email: String
    var role: String
    var plan: String?
    var isVerified: Bool
}

struct APIMessage: Codable {
    var message: String
    var debugToken: String?
}

struct APISoundPattern: Codable, Equatable {
    var timeOfDay: String
    var description: String
    var icon: String
}

struct APIMemory: Codable, Equatable {
    var id: UUID
    var time: String
    var title: String
    var emoji: String
    var category: String
    var dateLabel: String
}

struct APIPet: Codable, Equatable {
    var id: UUID
    var name: String
    var species: String
    var breed: String
    var sex: String
    var ageYears: Int
    var ageMonths: Int
    var avatarEmoji: String
    var colorHex: String
    var birthDate: Date?
    var customSpecies: String?
    var wellnessScore: Int
    var playfulness: Int
    var social: Int
    var vocal: Int
    var statusSummary: String
    var todayMoodEmoji: String? = nil
    var todayMoodTitle: String? = nil
    var moodConfidence: Int? = nil
    var moodTrendPercentage: Int? = nil
    var isTrendPositive: Bool? = nil
    var needsAttention: Bool? = nil
    var memberRole: String? = nil
    var soundPatterns: [APISoundPattern]? = nil
    var memories: [APIMemory]? = nil
    var createdAt: Date?
    var updatedAt: Date?
}

struct APIPetPage: Codable {
    var items: [APIPet]
    var page: Int
    var pageSize: Int
    var total: Int
}

struct APICareTask: Codable, Equatable {
    var id: UUID
    var petId: UUID?
    var title: String
    var timeText: String
    var frequency: String
    var alarmEnabled: Bool
    var emoji: String
    var customInterval: Int
    var customUnit: String
    var selectedDays: [Int]
    var isCompleted: Bool
    var completedForPetIds: [UUID]
    var startDate: Date?
    var completedDateOffset: Int?
    var completedPetDateOffsets: [String: Int]
    var taskKind: String?
    var snoozedUntil: Date?
    var occurrenceLog: [APITaskOccurrence]?
    var createdAt: Date?
    var updatedAt: Date?
}

struct APITaskOccurrence: Codable, Equatable {
    var id: UUID
    var status: String
    var occurredAt: Date
    var petId: UUID?
    var amountGrams: Double?
    var calories: Double?
    var foodName: String?
}

struct APIHealthRecord: Codable, Equatable {
    var id: UUID
    var petId: UUID?
    var title: String
    var recordType: String
    var notes: String
    var doctorOrLocation: String
    var reminderEnabled: Bool
    var dateText: String
    var date: Date?
    var nextDueDate: Date?
    var vaccineName: String?
    var upcomingDaysRemaining: Int?
    var frequency: String
    var customInterval: Int
    var customUnit: String
    var selectedDays: [Int]
    var createdAt: Date?
    var updatedAt: Date?
}

struct APIFood: Codable, Equatable {
    var id: UUID
    var petId: UUID?
    var name: String
    var brand: String
    var productName: String
    var category: String
    var caloriesPer100g: Double?
    var protein: Double?
    var fat: Double?
    var fiber: Double?
    var notes: String
    var isFavorite: Bool
}

struct APIFeeding: Codable, Equatable {
    var id: UUID
    var petId: UUID?
    var foodId: UUID?
    var fedAt: Date
    var foodName: String
    var brand: String
    var amountGrams: Double
    var amountKg: Double?
    var calories: Double?
    var notes: String
}

struct APIWeight: Codable, Equatable {
    var id: UUID
    var petId: UUID?
    var weight: Double
    var unit: String
    var loggedAt: Date
    var notes: String
}

struct APIBehavior: Codable, Equatable {
    var id: UUID
    var petId: UUID?
    var kind: String
    var title: String
    var occurredAt: Date
    var durationMinutes: Int
    var notes: String
    var mood: String
    var severity: Int
    var location: String
    var icon: String
    var colorHex: String
}

struct APINutritionInsight: Codable {
    var disclaimer: String
    var source: String
    var dailyCalories: Int
    var caloriesPerMeal: Int
    var suggestedGramsPerServing: Int?
    var estimatedCalories: Int
    var estimatedProteinG: Double?
    var estimatedFatG: Double?
    var estimatedFiberG: Double?
    var notes: [String]
}

struct APIFoodSuggest: Codable {
    var disclaimer: String
    var source: String
    var name: String
    var brand: String
    var productName: String
    var category: String
    var caloriesPer100g: Double
    var proteinPer100g: Double?
    var fatPer100g: Double?
    var fiberPer100g: Double?
    var suggestedGrams: Int
    var suggestedCalories: Int
    var notes: [String]
}

struct APIBehaviorInsight: Codable {
    var disclaimer: String
    var source: String
    var window: String
    var highlights: [String]
    var counts: [String: Int]
}

struct APIHealthSummary: Codable {
    var disclaimer: String
    var source: String
    var window: String
    var nutritionSummary: String
    var activitySummary: String
    var weightSummary: String
    var highlights: [String]
}

struct APINamedCount: Codable, Equatable {
    var name: String
    var count: Int
}

struct APIWeightPoint: Codable, Equatable, Identifiable {
    var loggedAt: Date
    var kilograms: Double
    var id: Date { loggedAt }
}

struct APIPeriodAnalytics: Codable, Equatable {
    var days: Int
    var calories: Double
    var meals: Int
    var feedingDays: Int
    var foods: [APINamedCount]
    var brands: [APINamedCount]
    var recommendedDaily: Int?
    var behaviors: [APINamedCount]
    var walkCount: Int
    var parkCount: Int
    var trainingCount: Int
    var socialCount: Int
    var activeMinutes: Int
    var weightDeltaKg: Double?
    var latestWeightKg: Double?
    var weightDirection: String
    var tasksDone: Int
    var tasksScheduled: Int
    var tasksMissed: Int
    var completionPercent: Int
    var positiveStreak: Int
    var dailyStreak: Int
}

struct APIAnalyticsReport: Codable, Equatable {
    var week: APIPeriodAnalytics
    var month: APIPeriodAnalytics
    var weights: [APIWeightPoint]
}

struct APITaskTemplate: Codable, Equatable {
    var id: UUID
    var title: String
    var emoji: String
    var taskKind: String
    var timeText: String
    var frequency: String
    var customInterval: Int
    var customUnit: String
    var selectedDays: [Int]
    var alarmEnabled: Bool
    var appliesToAllPets: Bool
    var petIds: [UUID]
}

struct APISyncSnapshot: Codable {
    var pets: [APIPet]
    var tasks: [APICareTask]
    var healthRecords: [APIHealthRecord]
    var reminders: [String]? = nil
    var foods: [APIFood]? = nil
    var feedings: [APIFeeding]? = nil
    var weights: [APIWeight]? = nil
    var behaviors: [APIBehavior]? = nil
    var taskTemplates: [APITaskTemplate]? = nil
    var revision: Int? = nil
    var householdRole: String? = nil
}

struct APIHouseholdMember: Codable, Identifiable, Equatable {
    var id: UUID
    var userId: UUID?
    var email: String
    var role: String
    var status: String
    var expiresAt: Date?
}

enum HouseholdRoleName {
    static func title(_ role: String) -> String {
        switch role {
        case "owner": return "Pet Owner"
        case "family": return "Family Member"
        case "sitter": return "Pet Sitter"
        case "viewer": return "Viewer"
        default: return role
        }
    }

    static let inviteRoles = ["family", "sitter", "viewer"]
}

struct APIAssistantSession: Codable {
    var id: UUID
    var petId: UUID?
    var title: String
    var createdAt: Date?
    var updatedAt: Date?
    var messages: [APIAssistantMessage]?
}

struct APIAssistantMessage: Codable {
    var id: UUID
    var content: String
    var role: String
    var createdAt: Date?
}
