//
//  RecordHeroCard.swift
//  CatEmotionAI
//
//  The dashboard's main call-to-action: a large animated microphone button
//  that will eventually launch real audio recording. For now it navigates
//  to the RecordingView mockup.
//

import SwiftUI

struct RecordHeroCard: View {
    let statusText: String
    var onTap: () -> Void

    @State private var pulse = false

    var body: some View {
        VStack(spacing: AppTheme.spacingM) {
            Button(action: onTap) {
                ZStack {
                    Circle()
                        .fill(AppTheme.primary.opacity(0.15))
                        .frame(width: 140, height: 140)
                        .scaleEffect(pulse ? 1.08 : 1.0)

                    Circle()
                        .fill(AppTheme.micGradient)
                        .frame(width: 104, height: 104)
                        .shadow(color: AppTheme.primary.opacity(0.4), radius: 20, y: 10)

                    Image(systemName: "mic.fill")
                        .font(.system(size: 40, weight: .semibold))
                        .foregroundStyle(.white)
                }
            }
            .buttonStyle(PressableButtonStyle())
            .onAppear {
                withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) {
                    pulse = true
                }
            }

            VStack(spacing: 4) {
                Text("Record Pet Sound")
                    .font(.headline)
                    .foregroundStyle(AppTheme.textPrimary)

                HStack(spacing: 6) {
                    Circle()
                        .fill(AppTheme.success)
                        .frame(width: 8, height: 8)
                    Text(statusText)
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.textSecondary)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppTheme.spacingXL)
        .padding(.horizontal, AppTheme.spacingM)
        .cardStyle(cornerRadius: AppTheme.cornerRadiusLarge)
    }
}

#Preview {
    RecordHeroCard(statusText: "Ready to analyze", onTap: {})
        .padding()
        .background(AppTheme.background)
}
