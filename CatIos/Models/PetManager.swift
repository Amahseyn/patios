//
//  PetManager.swift
//  CatIos
//

import Foundation
import Combine

class PetManager: ObservableObject {
    static let shared = PetManager()

    @Published var pets: [PetProfile] = PetProfile.mockList
    @Published var selectedPetId: UUID = PetProfile.mockLuna.id

    static let allPetsId = UUID(uuidString: "00000000-0000-0000-0000-000000000000")!

    var isAllPetsSelected: Bool {
        selectedPetId == PetManager.allPetsId
    }

    var currentPet: PetProfile {
        pets.first(where: { $0.id == selectedPetId }) ?? pets.first ?? PetProfile.mockLuna
    }

    var displayScopeName: String {
        isAllPetsSelected ? "All Pets" : currentPet.name
    }

    var averageWellness: Int {
        guard !pets.isEmpty else { return 100 }
        let total = pets.reduce(0) { $0 + $1.wellnessScore }
        return total / pets.count
    }

    func selectPet(id: UUID) {
        selectedPetId = id
    }

    func addPet(name: String, breed: String, age: AgeValue, petType: PetType = .cat, customPetTypeName: String? = nil, avatarEmoji: String? = nil, petColorHex: String? = nil) {
        let finalAvatar = avatarEmoji ?? petType.defaultAvatar
        let finalBreed = breed.isEmpty ? petType.defaultBreed : breed
        let memoryTitle = petType == .cat ? "Welcome to the family!" : "Welcome to the pack!"

        let newPet = PetProfile(
            id: UUID(),
            name: name,
            age: age,
            breed: finalBreed,
            gender: .female,
            petType: petType,
            customPetTypeName: customPetTypeName,
            wellnessScore: 90,
            avatarEmoji: finalAvatar,
            statusSummary: "Healthy & Happy",
            todayMoodEmoji: "😊",
            todayMoodTitle: "Happy",
            moodConfidence: 90,
            moodTrendPercentage: 10,
            isTrendPositive: true,
            needsAttention: false,
            userRole: .owner,
            birthDate: nil,
            petColorHex: petColorHex ?? "#9B59B6",
            playfulness: 80,
            social: 80,
            vocal: 60,
            soundPatterns: [
                SoundPattern(timeOfDay: "Morning", description: "Greeting sound", icon: "sun.max.fill")
            ],
            memories: [
                MemoryItem(time: "Just now", title: memoryTitle, emoji: "🎉", category: "System")
            ]
        )
        pets.append(newPet)
        selectedPetId = newPet.id
    }

    func removePet(id: UUID) {
        pets.removeAll(where: { $0.id == id })
        if selectedPetId == id, let first = pets.first {
            selectedPetId = first.id
        }
    }

    func addMemoryToCurrentPet(time: String, title: String, emoji: String, category: String) {
        guard let index = pets.firstIndex(where: { $0.id == selectedPetId }) else { return }
        let newItem = MemoryItem(time: time, title: title, emoji: emoji, category: category, dateLabel: "Today")
        pets[index].memories.insert(newItem, at: 0)
    }

    func updatePet(_ pet: PetProfile) {
        guard let index = pets.firstIndex(where: { $0.id == pet.id }) else { return }
        pets[index] = pet
    }
}
