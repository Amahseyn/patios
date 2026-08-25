//
//  AICatAssistantView.swift
//  CatIos
//
//  Compatibility shim — use PetAIAssistantView for new code.

import SwiftUI

struct AICatAssistantView: View {
    var body: some View {
        PetAIAssistantView()
    }
}

#Preview {
    AICatAssistantView()
        .environmentObject(PetManager.shared)
}
