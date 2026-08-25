//
//  EmotionCards.swift
//  CatEmotionAI
//
//  Reusable card views for displaying an analysis result in list contexts
//  (Home's "Recent Analysis" and the History screen).
//

import SwiftUI

/// Compact round badge showing an emotion's emoji on a tinted background.
struct EmotionBadge: View {
    let emotion: CatEmotion
    var size: CGFloat = 44

    var body: some View {
        ZStack {
            Circle()
                .fill(emotion.tint.opacity(0.15))
            Text(emotion.emoji)
                .font(.system(size: size * 0.5))
        }
        .frame(width: size, height: size)
    }
}

/// Row-style card used for "Recent Analysis" on Home and in History list.
struct AnalysisRowCard: View {
    let result: AnalysisResult

    var body: some View {
        HStack(spacing: AppTheme.spacingM) {
            EmotionBadge(emotion: result.emotion)

            VStack(alignment: .leading, spacing: 4) {
                Text(result.emotion.displayName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.textPrimary)

                Text(result.relativeDateText)
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(result.confidencePercentText)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(result.emotion.tint)
                Text("Confidence")
                    .font(.caption2)
                    .foregroundStyle(AppTheme.textSecondary)
            }
        }
        .padding(AppTheme.spacingM)
        .cardStyle(cornerRadius: AppTheme.cornerRadiusSmall)
    }
}

/// Full detail card used in the History screen with date + duration.
struct HistoryDetailCard: View {
    let result: AnalysisResult

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacingS) {
            HStack {
                Text(Self.fullDateFormatter.string(from: result.date))
                    .font(.caption.weight(.medium))
                    .foregroundStyle(AppTheme.textSecondary)
                Spacer()
                Label(result.durationText, systemImage: "clock")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(AppTheme.textSecondary)
            }

            HStack(spacing: AppTheme.spacingM) {
                EmotionBadge(emotion: result.emotion, size: 52)

                VStack(alignment: .leading, spacing: 4) {
                    Text(result.emotion.displayName)
                        .font(.title3.weight(.bold))
                        .foregroundStyle(AppTheme.textPrimary)
                    Text(result.emotion.sampleDescription)
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                        .lineLimit(2)
                }

                Spacer()

                Text(result.confidencePercentText)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(result.emotion.tint)
            }

            ConfidenceProgressBar(progress: result.confidence, tint: result.emotion.tint)
        }
        .padding(AppTheme.spacingM)
        .cardStyle()
    }

    private static let fullDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter
    }()
}

#Preview {
    VStack(spacing: 16) {
        AnalysisRowCard(result: MockData.recentAnalyses[0])
        HistoryDetailCard(result: MockData.recentAnalyses[1])
    }
    .padding()
    .background(AppTheme.background)
}
