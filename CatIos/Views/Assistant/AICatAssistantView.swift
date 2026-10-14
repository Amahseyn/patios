//
//  AICatAssistantView.swift
//  CatIos
//
//  Compatibility shim — use PetAIAssistantView for new code.

import SwiftUI

struct AICatAssistantView: View {
    var body: some View {
        ProfileAIView()
    }
}

#Preview {
    AICatAssistantView()
        .environmentObject(PetManager.shared)
        .environmentObject(AuthSession.shared)
        .environmentObject(AssistantSessionStore.shared)
}
