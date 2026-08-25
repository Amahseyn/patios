//
//  CatProfileCard.swift
//  CatEmotionAI
//
//  Small top-of-dashboard card showing the active pet's avatar and name.
//

import SwiftUI

struct CatProfileCard: View {
    let profile: PetProfile

    var body: some View {
        PetProfileCard(profile: profile)
    }
}

#Preview {
    CatProfileCard(profile: .mockLuna)
        .padding()
}
