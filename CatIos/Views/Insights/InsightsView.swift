//
//  InsightsView.swift
//  CatEmotionAI
//

import SwiftUI
import Charts

struct InsightsView: View {
    @EnvironmentObject private var petManager: PetManager

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.spacingL) {
                    weeklyMoodReportCard

                    moodTrendChartCard

                    vocalActivityChartCard

                    aiBehaviorSummaryCard
                }
                .padding(AppTheme.spacingM)
            }
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle("Mood & Insights")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var weeklyMoodReportCard: some View {
        let days = [
            ("Mon", "😊"),
            ("Tue", "😊"),
            ("Wed", "😐"),
            ("Thu", "😊"),
            ("Fri", "❤️"),
            ("Sat", "😊"),
            ("Sun", "😊")
        ]

        return VStack(alignment: .leading, spacing: AppTheme.spacingM) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Weekly Mood Report")
                        .font(.headline)
                        .foregroundStyle(AppTheme.textPrimary)
                    Text("Last 7 Days Analysis")
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                }
                Spacer()
                Text("94% Positivity")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(AppTheme.success)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(AppTheme.success.opacity(0.12))
                    .clipShape(Capsule())
            }

            HStack(spacing: 0) {
                ForEach(days, id: \.0) { day, emoji in
                    VStack(spacing: 8) {
                        Text(day)
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(AppTheme.textSecondary)

                        Text(emoji)
                            .font(.title2)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(AppTheme.spacingM)
        .cardStyle()
    }

    private var moodTrendChartCard: some View {
        let trendData: [(day: String, score: Int)] = [
            ("Mon", 85),
            ("Tue", 88),
            ("Wed", 70),
            ("Thu", 90),
            ("Fri", 98),
            ("Sat", 92),
            ("Sun", 95)
        ]

        return VStack(alignment: .leading, spacing: AppTheme.spacingM) {
            Label("Mood Stability Trend", systemImage: "chart.line.uptrend.xyaxis")
                .font(.headline)
                .foregroundStyle(AppTheme.primary)

            Chart {
                ForEach(trendData, id: \.day) { item in
                    LineMark(
                        x: .value("Day", item.day),
                        y: .value("Mood Index", item.score)
                    )
                    .foregroundStyle(AppTheme.primary)
                    .interpolationMethod(.catmullRom)

                    AreaMark(
                        x: .value("Day", item.day),
                        y: .value("Mood Index", item.score)
                    )
                    .foregroundStyle(
                        LinearGradient(colors: [AppTheme.primary.opacity(0.3), AppTheme.primary.opacity(0.0)], startPoint: .top, endPoint: .bottom)
                    )
                    .interpolationMethod(.catmullRom)

                    PointMark(
                        x: .value("Day", item.day),
                        y: .value("Mood Index", item.score)
                    )
                    .foregroundStyle(AppTheme.primary)
                }
            }
            .frame(height: 160)
        }
        .padding(AppTheme.spacingM)
        .cardStyle()
    }

    private var vocalActivityChartCard: some View {
        let vocalData: [(time: String, meows: Int)] = [
            ("8 AM", 6),
            ("12 PM", 2),
            ("4 PM", 3),
            ("8 PM", 9),
            ("11 PM", 4)
        ]

        return VStack(alignment: .leading, spacing: AppTheme.spacingM) {
            Label("Vocal Activity Frequency", systemImage: "waveform.path.ecg")
                .font(.headline)
                .foregroundStyle(Color.purple)

            Chart {
                ForEach(vocalData, id: \.time) { item in
                    BarMark(
                        x: .value("Time", item.time),
                        y: .value("Vocalizations", item.meows)
                    )
                    .foregroundStyle(Color.purple.gradient)
                    .cornerRadius(6)
                }
            }
            .frame(height: 150)
        }
        .padding(AppTheme.spacingM)
        .cardStyle()
    }

    private var aiBehaviorSummaryCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacingM) {
            HStack(spacing: AppTheme.spacingM) {
                ZStack {
                    Circle()
                        .fill(AppTheme.success.opacity(0.15))
                        .frame(width: 48, height: 48)
                    Image(systemName: "figure.walk")
                        .font(.title2)
                        .foregroundStyle(AppTheme.success)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Activity Level")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppTheme.textSecondary)
                    Text("High & Playful")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(AppTheme.textPrimary)
                }
            }

            Divider()

            HStack(alignment: .top, spacing: AppTheme.spacingS) {
                Image(systemName: "sparkles")
                    .foregroundStyle(AppTheme.primary)
                Text("\"Your pet has been more active this week, showing regular play routines and high vocal contentment.\"")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textPrimary)
            }
        }
        .padding(AppTheme.spacingM)
        .cardStyle()
    }
}

#Preview {
    InsightsView()
        .environmentObject(PetManager.shared)
}
