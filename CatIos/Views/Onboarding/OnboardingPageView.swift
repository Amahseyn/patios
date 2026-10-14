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

            onboardingHero
                .scaleEffect(animateIn ? 1 : 0.92)
                .opacity(animateIn ? 1 : 0)

            VStack(spacing: AppTheme.spacingM) {
                Text(page.title)
                    .font(AppTypography.title2)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(AppTheme.textPrimary)

                Text(page.description)
                    .font(AppTypography.body)
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

    @ViewBuilder
    private var onboardingHero: some View {
        if let imageName = page.imageName {
            Image(imageName)
                .resizable()
                .scaledToFit()
                .frame(width: 140, height: 140)
                .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
                .shadow(color: AppTheme.shadowColor, radius: 12, y: 6)
                .accessibilityLabel("Patios app logo")
        } else if let systemImage = page.systemImage {
            ZStack {
                Circle()
                    .fill(AppTheme.heroGradient)
                    .frame(width: 120, height: 120)
                Image(systemName: systemImage)
                    .font(.system(size: 52))
                    .foregroundStyle(.white)
            }
            .shadow(color: AppTheme.primary.opacity(0.35), radius: 16, y: 8)
        }
    }
}

#Preview {
    OnboardingPageView(page: OnboardingViewModel().pages[0])
}
