import SwiftUI

struct FantasyScreenBackground: View {
    var body: some View {
        AppTheme.background
    }
}

struct EnchantedIconBadge: View {
    let systemImage: String
    var tint: Color = AppTheme.primary
    var size: CGFloat = 52

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.28, style: .continuous)
                .fill(tint.opacity(0.14))
            Image(systemName: systemImage)
                .font(.system(size: size * 0.4, weight: .semibold))
                .foregroundStyle(tint)
                .symbolRenderingMode(.hierarchical)
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

struct FantasySectionHeader: View {
    let title: String
    var subtitle: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(LocalizedStringKey(title))
                .font(AppTheme.headlineFont())
                .foregroundStyle(AppTheme.textPrimary)
            if let subtitle {
                Text(LocalizedStringKey(subtitle))
                    .font(AppTheme.captionFont())
                    .foregroundStyle(AppTheme.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 2)
        .textCase(nil)
    }
}

struct FantasyHeroHeader: View {
    let title: String
    let subtitle: String
    var systemImage: String = "pawprint.fill"

    var body: some View {
        HStack(alignment: .top, spacing: AppTheme.spacingM) {
            EnchantedIconBadge(systemImage: systemImage, tint: AppTheme.primary, size: 52)
            VStack(alignment: .leading, spacing: 6) {
                Text(LocalizedStringKey(title))
                    .font(AppTheme.titleFont(22))
                    .foregroundStyle(AppTheme.textPrimary)
                Text(LocalizedStringKey(subtitle))
                    .font(AppTheme.bodyFont())
                    .foregroundStyle(AppTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(AppTheme.spacingM)
        .cardStyle(cornerRadius: AppTheme.cornerRadiusLarge)
    }
}

struct FantasyTopicChip: View {
    let title: String
    let systemImage: String
    var tint: Color = AppTheme.primary

    var body: some View {
        Label(LocalizedStringKey(title), systemImage: systemImage)
            .font(AppTheme.captionFont().weight(.semibold))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background {
                Capsule(style: .continuous)
                    .fill(tint.opacity(0.12))
            }
            .foregroundStyle(tint)
    }
}

struct CareSummaryCard: View {
    let headline: String
    let detail: String
    let remaining: Int
    let overdue: Int
    var progress: Double = 0
    var total: Int = 0

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacingS) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(LocalizedStringKey(headline))
                        .font(AppTheme.headlineFont())
                        .foregroundStyle(overdue > 0 ? AppTheme.danger : AppTheme.textPrimary)
                    Text(LocalizedStringKey(detail))
                        .font(AppTheme.captionFont())
                        .foregroundStyle(AppTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 8)
                if total > 0 {
                    Text("\(remaining)")
                        .font(.system(size: 28, weight: .semibold, design: .rounded))
                        .foregroundStyle(overdue > 0 ? AppTheme.danger : AppTheme.primary)
                        .accessibilityLabel("\(remaining) remaining")
                }
            }
            if total > 0 {
                ProgressView(value: progress)
                    .tint(overdue > 0 ? AppTheme.danger : AppTheme.primary)
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }
}
