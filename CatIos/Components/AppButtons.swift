//
//  AppButtons.swift
//  CatEmotionAI
//
//  Reusable button styles used throughout the app for a consistent,
//  premium feel with large touch targets and subtle press animations.
//

import SwiftUI
import UIKit

/// Full-width, gradient-filled primary call-to-action button.
struct PrimaryButton: View {
    let title: String
    var systemImage: String? = nil
    var action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: {
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            action()
        }) {
            HStack(spacing: AppTheme.spacingS) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.headline)
                }
                Text(title)
                    .font(.headline)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(AppTheme.heroGradient)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadiusMedium, style: .continuous))
        }
        .buttonStyle(PressableButtonStyle())
    }
}

/// Outlined secondary button, used for less prominent actions.
struct SecondaryButton: View {
    let title: String
    var systemImage: String? = nil
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: AppTheme.spacingS) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.headline)
                }
                Text(title)
                    .font(.headline)
            }
            .foregroundStyle(AppTheme.primary)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(AppTheme.primary.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadiusMedium, style: .continuous))
        }
        .buttonStyle(PressableButtonStyle())
    }
}

/// Adds a subtle scale-down animation on press for a tactile feel.
struct PressableButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

#Preview {
    VStack(spacing: 16) {
        PrimaryButton(title: "Record Cat Sound", systemImage: "mic.fill") {}
        SecondaryButton(title: "Analyze Again", systemImage: "arrow.clockwise") {}
    }
    .padding()
}
