//
//  RootView.swift
//  CatEmotionAI
//
//  Decides whether to show onboarding (first launch) or the main tab bar.
//  Persists completion with @AppStorage so onboarding only shows once —
//  purely a UI-state flag, no backend involved.
//

import SwiftUI

struct RootView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false

    var body: some View {
        Group {
            if hasCompletedOnboarding {
                MainTabView()
                    .transition(.opacity)
            } else {
                OnboardingView {
                    withAnimation(.easeInOut) {
                        hasCompletedOnboarding = true
                    }
                }
                .transition(.opacity)
            }
        }
        .animation(.easeInOut, value: hasCompletedOnboarding)
    }
}

#Preview {
    RootView()
}
