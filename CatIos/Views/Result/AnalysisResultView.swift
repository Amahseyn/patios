//
//  AnalysisResultView.swift
//  CatEmotionAI
//
//  Beautiful result presentation for a completed (mock) analysis.
//

import SwiftUI

struct AnalysisResultView: View {
    let result: AnalysisResult

    @Environment(\.dismiss) private var dismiss
    @State private var animateIn = false

    var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.spacingXL) {
                resultCard
                descriptionCard
                actionButtons
            }
            .padding(AppTheme.spacingM)
            .padding(.top, AppTheme.spacingL)
        }
        .background(AppTheme.background.ignoresSafeArea())
        .navigationTitle("Analysis Result")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.75)) {
                animateIn = true
            }
        }
    }

    private var resultCard: some View {
        VStack(spacing: AppTheme.spacingM) {
            ZStack {
                Circle()
                    .fill(result.emotion.tint.opacity(0.15))
                    .frame(width: 150, height: 150)
                Text(result.emotion.emoji)
                    .font(.system(size: 70))
            }
            .scaleEffect(animateIn ? 1.0 : 0.7)
            .opacity(animateIn ? 1.0 : 0.0)

            Text(result.emotion.displayName)
                .font(.largeTitle.weight(.bold))
                .foregroundStyle(AppTheme.textPrimary)

            VStack(spacing: AppTheme.spacingS) {
                HStack {
                    Text("Confidence")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(AppTheme.textSecondary)
                    Spacer()
                    Text(result.confidencePercentText)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(result.emotion.tint)
                }
                ConfidenceProgressBar(progress: result.confidence, tint: result.emotion.tint)
            }
        }
        .padding(AppTheme.spacingL)
        .frame(maxWidth: .infinity)
        .cardStyle(cornerRadius: AppTheme.cornerRadiusLarge)
    }

    private var descriptionCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacingS) {
            Label("What this means", systemImage: "sparkles")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppTheme.primary)

            Text(result.emotion.sampleDescription)
                .font(.body)
                .foregroundStyle(AppTheme.textPrimary)

            Divider().padding(.vertical, 4)

            HStack {
                Label(result.relativeDateText, systemImage: "calendar")
                Spacer()
                Label(result.durationText, systemImage: "waveform")
            }
            .font(.caption)
            .foregroundStyle(AppTheme.textSecondary)
        }
        .padding(AppTheme.spacingM)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    private var actionButtons: some View {
        VStack(spacing: AppTheme.spacingM) {
            PrimaryButton(title: "Analyze Again", systemImage: "arrow.clockwise") {
                dismiss()
            }
        }
    }
}

#Preview {
    NavigationStack {
        AnalysisResultView(result: MockData.sampleResult)
    }
}
