//
//  HistoryView.swift
//  CatEmotionAI
//
//  Shows all previous (mock) analyses, with quick emotion filter chips.
//

import SwiftUI

struct HistoryView: View {
    @StateObject private var viewModel = HistoryViewModel()

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.filteredResults.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        LazyVStack(spacing: AppTheme.spacingM) {
                            ForEach(viewModel.filteredResults) { result in
                                NavigationLink {
                                    AnalysisResultView(result: result)
                                } label: {
                                    HistoryDetailCard(result: result)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(AppTheme.spacingM)
                    }
                }
            }
            .safeAreaInset(edge: .top) {
                filterBar
            }
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle("History")
        }
    }

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppTheme.spacingS) {
                FilterChip(title: "All", isSelected: viewModel.selectedFilter == nil) {
                    viewModel.selectedFilter = nil
                }
                ForEach(viewModel.availableFilters) { emotion in
                    FilterChip(
                        title: "\(emotion.emoji) \(emotion.displayName)",
                        isSelected: viewModel.selectedFilter == emotion
                    ) {
                        viewModel.selectedFilter = emotion
                    }
                }
            }
            .padding(.horizontal, AppTheme.spacingM)
            .padding(.vertical, AppTheme.spacingS)
        }
        .background(.ultraThinMaterial)
    }

    private var emptyState: some View {
        VStack(spacing: AppTheme.spacingM) {
            Image(systemName: "tray")
                .font(.system(size: 48))
                .foregroundStyle(AppTheme.textSecondary)
            Text("No analyses yet")
                .font(.headline)
                .foregroundStyle(AppTheme.textPrimary)
            Text("Record your cat's sounds to see history here.")
                .font(.subheadline)
                .foregroundStyle(AppTheme.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.medium))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(isSelected ? AppTheme.primary : AppTheme.cardBackground)
                .foregroundStyle(isSelected ? .white : AppTheme.textPrimary)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    HistoryView()
}
