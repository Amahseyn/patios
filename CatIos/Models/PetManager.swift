//
//  PetManager.swift
//  CatIos
//

import Foundation
import Combine

class PetManager: ObservableObject {
    static let shared = PetManager()

    func replaceFromRemote(_ pets: [PetProfile]) {
        self.pets = pets
        if pets.contains(where: { $0.id == selectedPetId }) == false {
            selectedPetId = pets.first?.id ?? selectedPetId
        }
    }

    @Published var pets: [PetProfile] = PetProfile.mockList {
        didSet { persist() }
    }
    @Published var selectedPetId: UUID = PetProfile.mockLuna.id {
        didSet { persist() }
    }

    private let database: AppDatabase
    private var isReady = false

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

    private init() {
        database = .shared
        if let saved = database.loadPets() {
            pets = saved.pets
            selectedPetId = saved.selectedPetId
        }
        isReady = true
        if database.loadPets() == nil {
            persist()
        }
    }

    func selectPet(id: UUID) {
        selectedPetId = id
    }

    func adoptOnboardingPet(name: String, petType: PetType, gender: PetGender) {
        let sampleIds: Set<UUID> = [PetProfile.mockLuna.id, PetProfile.mockMilo.id, PetProfile.mockBuddy.id]
        let replacingSamples = !pets.isEmpty && pets.allSatisfy { sampleIds.contains($0.id) }
        addPet(name: name, breed: "", age: AgeValue(years: 1, months: 0), petType: petType, gender: gender)
        guard replacingSamples else { return }
        pets.removeAll { sampleIds.contains($0.id) }
        if let kept = pets.last {
            selectedPetId = kept.id
            CareTaskStore.shared.replaceWithStarter(petId: kept.id)
            HealthRecordStore.shared.clearIfOnlySamplePets()
        }
    }

    func addPet(name: String, breed: String, age: AgeValue, petType: PetType = .cat, customPetTypeName: String? = nil, avatarEmoji: String? = nil, petColorHex: String? = nil, gender: PetGender = .female) {
        let finalAvatar = avatarEmoji ?? petType.defaultAvatar
        let finalBreed = breed.isEmpty ? petType.defaultBreed : breed
        let memoryTitle = "Welcome home."

        let newPet = PetProfile(
            id: UUID(),
            name: name,
            age: age,
            breed: finalBreed,
            gender: gender,
            petType: petType,
            customPetTypeName: customPetTypeName,
            wellnessScore: 90,
            avatarEmoji: finalAvatar,
            statusSummary: "Bright and well",
            todayMoodEmoji: "😊",
            todayMoodTitle: "Happy",
            moodConfidence: 90,
            moodTrendPercentage: 10,
            isTrendPositive: true,
            needsAttention: false,
            userRole: .owner,
            birthDate: nil,
            petColorHex: petColorHex ?? petType.accentHex,
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
        CareTaskStore.shared.detachPet(id)
        HealthRecordStore.shared.detachPet(id)
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

    private func persist() {
        guard isReady else { return }
        database.savePets(pets, selectedPetId: selectedPetId)
        NotificationCenter.default.post(name: .householdDidChange, object: nil)
    }
}
