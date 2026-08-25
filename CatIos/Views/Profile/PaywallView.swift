//
//  PaywallView.swift
//  CatIos
//

import SwiftUI

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var isYearlySelected: Bool = true

    var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.spacingL) {
                // Header Close Button
                HStack {
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                }
                .padding(.horizontal, AppTheme.spacingM)

                // Hero Banner
                VStack(spacing: AppTheme.spacingS) {
                    ZStack {
                        Circle()
                            .fill(LinearGradient(colors: [.orange, .pink], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 80, height: 80)
                        Image(systemName: "crown.fill")
                            .font(.system(size: 40))
                            .foregroundStyle(.white)
                    }

                    Text("Unlock Luna AI Premium")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.textPrimary)

                    Text("Get deep behavioral intelligence and unlimited voice analyses for your cat.")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, AppTheme.spacingM)
                }

                // Comparison Table Card
                VStack(alignment: .leading, spacing: AppTheme.spacingM) {
                    Text("Choose Your Plan")
                        .font(.headline)
                        .foregroundStyle(AppTheme.textPrimary)

                    VStack(spacing: AppTheme.spacingS) {
                        ComparisonRow(feature: "Daily Vocal Analyses", freeText: "5 / day", proText: "Unlimited")
                        ComparisonRow(feature: "Emotion Breakdown", freeText: "Basic", proText: "Deep AI")
                        ComparisonRow(feature: "Cat Personality Profile", freeText: "❌", proText: "Included")
                        ComparisonRow(feature: "Behavior Trends & History", freeText: "❌", proText: "Included")
                        ComparisonRow(feature: "Ask Luna AI Assistant", freeText: "❌", proText: "Included")
                        ComparisonRow(feature: "Multiple Cats Support", freeText: "❌", proText: "Unlimited")
                    }
                }
                .padding(AppTheme.spacingM)
                .cardStyle()

                // Pricing Toggle Selector
                HStack(spacing: AppTheme.spacingM) {
                    PricingOptionCard(
                        title: "Yearly Plan",
                        price: "$39.99 / yr",
                        subtext: "$3.33 / month",
                        badge: "SAVE 50%",
                        isSelected: isYearlySelected
                    ) {
                        isYearlySelected = true
                    }

                    PricingOptionCard(
                        title: "Monthly Plan",
                        price: "$6.99 / mo",
                        subtext: "Billed monthly",
                        badge: nil,
                        isSelected: !isYearlySelected
                    ) {
                        isYearlySelected = false
                    }
                }
                .padding(.horizontal, AppTheme.spacingM)

                // CTA Subscribe Button
                VStack(spacing: AppTheme.spacingS) {
                    Button {
                        dismiss()
                    } label: {
                        Text("Start 7-Day Free Trial")
                            .font(.headline.weight(.bold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                LinearGradient(colors: [.orange, .pink], startPoint: .leading, endPoint: .trailing)
                            )
                            .clipShape(Capsule())
                            .shadow(color: .pink.opacity(0.4), radius: 10, x: 0, y: 5)
                    }

                    Text("Cancel anytime in App Store settings.")
                        .font(.caption2)
                        .foregroundStyle(AppTheme.textSecondary)
                }
                .padding(.horizontal, AppTheme.spacingM)
                .padding(.bottom, AppTheme.spacingL)
            }
            .padding(.top, AppTheme.spacingS)
        }
        .background(AppTheme.background.ignoresSafeArea())
    }
}

struct ComparisonRow: View {
    let feature: String
    let freeText: String
    let proText: String

    var body: some View {
        HStack {
            Text(feature)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(AppTheme.textPrimary)

            Spacer()

            Text(freeText)
                .font(.caption)
                .foregroundStyle(AppTheme.textSecondary)
                .frame(width: 60, alignment: .trailing)

            Text(proText)
                .font(.caption.weight(.bold))
                .foregroundStyle(AppTheme.primary)
                .frame(width: 80, alignment: .trailing)
        }
        .padding(.vertical, 4)
    }
}

struct PricingOptionCard: View {
    let title: String
    let price: String
    let subtext: String
    let badge: String?
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 6) {
                if let badge = badge {
                    Text(badge)
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.red)
                        .clipShape(Capsule())
                } else {
                    Spacer().frame(height: 16)
                }

                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.textPrimary)

                Text(price)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(AppTheme.primary)

                Text(subtext)
                    .font(.caption2)
                    .foregroundStyle(AppTheme.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(AppTheme.spacingM)
            .cardStyle()
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.cornerRadiusMedium)
                    .stroke(isSelected ? AppTheme.primary : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    PaywallView()
}
