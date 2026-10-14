//
//  ProfileAIView.swift
//  CatEmotionAI
//

import SwiftUI

struct ProfileAIView: View {
    var body: some View {
        PetAIAssistantView()
    }
}

#Preview {
    ProfileAIView()
        .environmentObject(PetManager.shared)
}
