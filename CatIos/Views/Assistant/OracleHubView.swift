import SwiftUI

enum OracleSection: String, CaseIterable, Identifiable {
    case letters = "Chats"
    case starCharts = "Insights"

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .letters: return "bubble.left.and.bubble.right.fill"
        case .starCharts: return "chart.xyaxis.line"
        }
    }

    var subtitle: String {
        switch self {
        case .letters: return "Ask about meals, health, or routines"
        case .starCharts: return "Trends from tasks, meals, and activity"
        }
    }
}

struct OracleHubView: View {
    @Binding var path: NavigationPath
    @State private var section: OracleSection = .letters

    var body: some View {
        VStack(spacing: 0) {
            sectionPicker
                .padding(.horizontal, AppTheme.spacingM)
                .padding(.top, AppTheme.spacingS)
                .padding(.bottom, AppTheme.spacingS)

            switch section {
            case .letters:
                AssistantSessionListView(path: $path)
            case .starCharts:
                ActivityInsightsView()
            }
        }
        .fantasyScreen()
        .fantasyNavigation()
        .navigationTitle("Assistant")
    }

    private var sectionPicker: some View {
        HStack(spacing: AppTheme.spacingS) {
            ForEach(OracleSection.allCases) { item in
                sectionCard(item)
            }
        }
    }

    private func sectionCard(_ item: OracleSection) -> some View {
        let selected = section == item
        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                section = item
            }
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                Label(item.rawValue, systemImage: item.systemImage)
                    .font(AppTheme.headlineFont())
                Text(item.subtitle)
                    .font(AppTheme.captionFont())
                    .foregroundStyle(AppTheme.textSecondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(AppTheme.spacingM)
            .background {
                RoundedRectangle(cornerRadius: AppTheme.cornerRadiusMedium, style: .continuous)
                    .fill(selected ? AppTheme.primary.opacity(0.12) : AppTheme.cardBackground)
                    .overlay {
                        RoundedRectangle(cornerRadius: AppTheme.cornerRadiusMedium, style: .continuous)
                            .strokeBorder(selected ? AppTheme.primary.opacity(0.35) : AppTheme.enchantedBorder, lineWidth: 1)
                    }
            }
            .foregroundStyle(selected ? AppTheme.primary : AppTheme.textPrimary)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}
