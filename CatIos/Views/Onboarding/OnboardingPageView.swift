//
//  OnboardingPageView.swift
//  CatEmotionAI
//
//  Single onboarding step: illustration placeholder + title + description.
//

import SwiftUI

struct OnboardingPageView: View {
    let page: OnboardingPage

    @State private var animateIn = false

    var body: some View {
        VStack(spacing: AppTheme.spacingXL) {
            Spacer()


            VStack(spacing: AppTheme.spacingM) {
                Text(page.title)
                    .font(.title.weight(.bold))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(AppTheme.textPrimary)

                Text(page.description)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(AppTheme.textSecondary)
                    .padding(.horizontal, AppTheme.spacingL)
            }
            .opacity(animateIn ? 1.0 : 0.0)
            .offset(y: animateIn ? 0 : 12)

            Spacer()
            Spacer()
        }
        .onAppear {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.75)) {
                animateIn = true
            }
        }
    }
}

#Preview {
    OnboardingPageView(page: OnboardingViewModel().pages[0])
}
