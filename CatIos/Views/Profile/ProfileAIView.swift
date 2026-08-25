//
//  ProfileAIView.swift
//  CatEmotionAI
//

import SwiftUI

struct ProfileAIView: View {
    @EnvironmentObject private var petManager: PetManager
    @AppStorage("prefersDarkMode") private var prefersDarkMode: Bool = false

    var body: some View {
        NavigationStack {
            PetAIAssistantView()
                .background(AppTheme.background.ignoresSafeArea())
                .navigationTitle("AI Assistant")
                .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    ProfileAIView()
        .environmentObject(PetManager.shared)
}
