//
//  HistoryViewModel.swift
//  CatEmotionAI
//

import SwiftUI
import Combine

@MainActor
final class HistoryViewModel: ObservableObject {
    @Published var allResults: [AnalysisResult] = MockData.recentAnalyses
    @Published var selectedFilter: PetEmotion?

    var filteredResults: [AnalysisResult] {
        guard let selectedFilter else { return allResults }
        return allResults.filter { $0.emotion == selectedFilter }
    }

    var availableFilters: [PetEmotion] {
        let emotions = Set(allResults.map { $0.emotion })
        return PetEmotion.allCases.filter { emotions.contains($0) }
    }
}
