//
//  ProfileViewModel.swift
//  CatEmotionAI
//

import SwiftUI
import Combine

@MainActor
final class ProfileViewModel: ObservableObject {
    @Published var profile: PetProfile = .mockLuna
    @Published var isEditing: Bool = false
    @Published var draftProfile: PetProfile = .mockLuna

    func loadProfile(_ pet: PetProfile) {
        profile = pet
        draftProfile = pet
    }

    func beginEditing() {
        draftProfile = profile
        isEditing = true
    }

    func save() {
        profile = draftProfile
        isEditing = false
    }

    func cancel() {
        isEditing = false
    }
}
