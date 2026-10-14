//
//  PetProfile.swift
//  CatIos
//

import Foundation

enum UserRole: String, Codable, CaseIterable, Identifiable {
    case owner = "Pet Owner"
    case family = "Family Member"
    case petSitter = "Pet Sitter"
    case viewer = "Viewer"

    var id: String { rawValue }

    var description: String {
        switch self {
        case .owner: return "Full control: edit profile, health, reminders, invite others."
        case .family: return "Can view profile, photos, updates, and add comments."
        case .petSitter: return "Access to feeding schedules, reminders, and daily notes."
        case .viewer: return "Can view shared photos and approved pet information."
        }
    }

    var badgeColorName: String {
        switch self {
        case .owner: return "purple"
        case .family: return "blue"
        case .petSitter: return "orange"
        case .viewer: return "gray"
        }
    }
}

enum PetType: String, CaseIterable, Identifiable, Codable {
    case cat = "Cat"
    case dog = "Dog"
    case bird = "Bird"
    case rabbit = "Rabbit"
    case horse = "Horse"
    case fish = "Fish"
    case hamster = "Hamster"
    case reptile = "Reptile"
    case other = "Other"

    var id: String { rawValue }

    var systemIcon: String {
        switch self {
        case .cat, .dog: return "pawprint.fill"
        case .bird: return "bird.fill"
        case .rabbit: return "hare.fill"
        case .horse: return "horse"
        case .fish: return "fish.fill"
        case .hamster: return "hare.fill"
        case .reptile: return "lizard.fill"
        case .other: return "questionmark.circle.fill"
        }
    }

    var avatarEmojis: [String] {
        switch self {
        case .cat: return ["🐱", "🐈", "🦁", "🐅", "🐾", "😽", "😸"]
        case .dog: return ["🐶", "🐕", "🐩", "🦮", "🐕‍🦺", "🐾", "🐺"]
        case .bird: return ["🐦", "🦜", "🦅", "🦆", "🐧", "🕊️", "🦢"]
        case .rabbit: return ["🐰", "🐇", "🐾"]
        case .horse: return ["🐴", "🐎", "🐾"]
        case .fish: return ["🐠", "🐟", "🐡", "🦈", "🐙"]
        case .hamster: return ["🐹", "🐾"]
        case .reptile: return ["🦎", "🐊", "🐢", "🐍"]
        case .other: return ["🐾", "🐰", "🐹", "🦊", "🐻", "🐼", "🐸"]
        }
    }

    var defaultAvatar: String {
        switch self {
        case .cat: return "🐱"
        case .dog: return "🐶"
        case .bird: return "🐦"
        case .rabbit: return "🐰"
        case .horse: return "🐴"
        case .fish: return "🐠"
        case .hamster: return "🐹"
        case .reptile: return "🦎"
        case .other: return "🐾"
        }
    }

    var defaultBreed: String {
        switch self {
        case .cat: return "Domestic Short Hair"
        case .dog: return "Mixed Breed"
        case .bird: return "Companion Bird"
        case .rabbit: return "Domestic Rabbit"
        case .horse: return "Horse"
        case .fish: return "Freshwater"
        case .hamster: return "Hamster"
        case .reptile: return "Reptile"
        case .other: return "Companion"
        }
    }

    var accentHex: String {
        switch self {
        case .cat: return "#C45C86"
        case .dog: return "#D4922A"
        case .bird: return "#3D7EC4"
        case .rabbit: return "#E7A0C0"
        case .horse: return "#8B6BB5"
        case .fish: return "#3E9A6A"
        case .hamster: return "#D4654A"
        case .reptile: return "#6A5A9A"
        case .other: return "#C45C86"
        }
    }
}

enum PetGender: String, CaseIterable, Identifiable, Codable {
    case male = "Male"
    case female = "Female"
    case unknown = "Unknown"

    var id: String { rawValue }
}

struct TraitProgress: Identifiable, Codable {
    var id: String { name }
    let name: String
    let percentage: Int // 0..100
}

struct SoundPattern: Identifiable, Codable {
    var id: String { timeOfDay }
    let timeOfDay: String
    let description: String
    let icon: String
}

struct MemoryItem: Identifiable, Codable {
    let id: UUID
    let time: String
    let title: String
    let emoji: String
    let category: String
    let dateLabel: String

    init(id: UUID = UUID(), time: String, title: String, emoji: String, category: String, dateLabel: String = "Today") {
        self.id = id
        self.time = time
        self.title = title
        self.emoji = emoji
        self.category = category
        self.dateLabel = dateLabel
    }
}

struct AgeValue: Codable, Equatable {
    var years: Int
    var months: Int

    var isValid: Bool {
        years > 0 || months > 0
    }

    var displayText: String {
        if years > 0 && months > 0 {
            return "\(years) yr, \(months) mo"
        } else if years > 0 {
            return years == 1 ? "1 year" : "\(years) years"
        } else if months > 0 {
            return months == 1 ? "1 month" : "\(months) months"
        }
        return "Unknown"
    }

    var shortDisplayText: String {
        if years > 0 && months > 0 {
            return "\(years)y \(months)m"
        } else if years > 0 {
            return "\(years)y"
        } else if months > 0 {
            return "\(months)m"
        }
        return "?"
    }
}

struct PetProfile: Identifiable, Codable {
    var id: UUID = UUID()
    var name: String
    var age: AgeValue
    var breed: String
    var gender: PetGender
    var petType: PetType
    var customPetTypeName: String? = nil
    var wellnessScore: Int = 92
    var avatarEmoji: String
    var statusSummary: String
    var todayMoodEmoji: String
    var todayMoodTitle: String
    var moodConfidence: Int
    var moodTrendPercentage: Int
    var isTrendPositive: Bool
    var needsAttention: Bool
    var userRole: UserRole = .owner
    var birthDate: Date? = nil
    var petColorHex: String = "#9B59B6"

    var playfulness: Int
    var social: Int
    var vocal: Int

    var soundPatterns: [SoundPattern]
    var memories: [MemoryItem]

    var petTypeDisplayName: String {
        if petType == .other, let custom = customPetTypeName, !custom.isEmpty {
            return custom
        }
        return petType.rawValue
    }

    var exactAgeDisplay: String {
        age.displayText
    }

    static let mockLuna = PetProfile(
        id: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
        name: "Luna",
        age: AgeValue(years: 3, months: 2),
        breed: "Persian Cat",
        gender: .female,
        petType: .cat,
        wellnessScore: 92,
        avatarEmoji: "🐱",
        statusSummary: "Happy",
        todayMoodEmoji: "😊",
        todayMoodTitle: "Happy",
        moodConfidence: 92,
        moodTrendPercentage: 12,
        isTrendPositive: true,
        needsAttention: false,
        userRole: .owner,
        birthDate: nil,
        petColorHex: "#FF9FF3",
        playfulness: 80,
        social: 70,
        vocal: 90,
        soundPatterns: [
            SoundPattern(timeOfDay: "Morning", description: "Attention seeking", icon: "sun.max.fill"),
            SoundPattern(timeOfDay: "Evening", description: "Food related", icon: "sunset.fill"),
            SoundPattern(timeOfDay: "Night", description: "Comfort seeking", icon: "moon.stars.fill")
        ],
        memories: [
            MemoryItem(time: "09:00", title: "Breakfast", emoji: "🍖", category: "Meal"),
            MemoryItem(time: "11:30", title: "Happy vocalization detected", emoji: "😊", category: "Sound"),
            MemoryItem(time: "15:00", title: "Rest period", emoji: "😴", category: "Rest"),
            MemoryItem(time: "19:00", title: "Play session", emoji: "🎮", category: "Activity")
        ]
    )

    static let mockMilo = PetProfile(
        id: UUID(uuidString: "22222222-2222-2222-2222-222222222222")!,
        name: "Milo",
        age: AgeValue(years: 2, months: 6),
        breed: "British Shorthair",
        gender: .male,
        petType: .cat,
        wellnessScore: 78,
        avatarEmoji: "🐈",
        statusSummary: "Needs attention",
        todayMoodEmoji: "😐",
        todayMoodTitle: "Restless",
        moodConfidence: 78,
        moodTrendPercentage: 5,
        isTrendPositive: false,
        needsAttention: true,
        userRole: .owner,
        birthDate: nil,
        petColorHex: "#54A0FF",
        playfulness: 95,
        social: 60,
        vocal: 50,
        soundPatterns: [
            SoundPattern(timeOfDay: "Morning", description: "Morning zoomies meow", icon: "sun.max.fill"),
            SoundPattern(timeOfDay: "Afternoon", description: "Window bird chirping", icon: "bird.fill"),
            SoundPattern(timeOfDay: "Night", description: "Quiet purring", icon: "moon.fill")
        ],
        memories: [
            MemoryItem(time: "08:15", title: "Crispy treats eaten", emoji: "🐟", category: "Meal"),
            MemoryItem(time: "10:00", title: "Curious window bird-watching sound", emoji: "👀", category: "Behavior"),
            MemoryItem(time: "14:20", title: "Afternoon nap under sunbeam", emoji: "☀️", category: "Rest"),
            MemoryItem(time: "18:30", title: "Feather wand toy chase", emoji: "🪶", category: "Activity")
        ]
    )

    static let mockBuddy = PetProfile(
        id: UUID(uuidString: "44444444-4444-4444-4444-444444444444")!,
        name: "Buddy",
        age: AgeValue(years: 4, months: 0),
        breed: "Golden Retriever",
        gender: .male,
        petType: .dog,
        wellnessScore: 88,
        avatarEmoji: "🐶",
        statusSummary: "Happy & Active",
        todayMoodEmoji: "😊",
        todayMoodTitle: "Excited",
        moodConfidence: 90,
        moodTrendPercentage: 15,
        isTrendPositive: true,
        needsAttention: false,
        userRole: .owner,
        birthDate: nil,
        petColorHex: "#FF9F43",
        playfulness: 95,
        social: 90,
        vocal: 60,
        soundPatterns: [
            SoundPattern(timeOfDay: "Morning", description: "Happy barking", icon: "sun.max.fill"),
            SoundPattern(timeOfDay: "Evening", description: "Playful whining", icon: "sunset.fill"),
            SoundPattern(timeOfDay: "Night", description: "Quiet resting", icon: "moon.stars.fill")
        ],
        memories: [
            MemoryItem(time: "07:00", title: "Morning walk", emoji: "🦮", category: "Activity"),
            MemoryItem(time: "09:00", title: "Breakfast served", emoji: "🦴", category: "Meal"),
            MemoryItem(time: "18:00", title: "Park fetch session", emoji: "🎾", category: "Activity"),
            MemoryItem(time: "20:00", title: "Cuddle time", emoji: "❤️", category: "Rest")
        ]
    )

    static let mockList: [PetProfile] = [mockLuna, mockMilo, mockBuddy]
}
