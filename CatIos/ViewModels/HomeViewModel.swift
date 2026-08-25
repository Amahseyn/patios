//
//  HomeViewModel.swift
//  CatEmotionAI
//

import SwiftUI
import Combine

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var petProfile: PetProfile = .mockLuna
    @Published var recentAnalyses: [AnalysisResult] = Array(MockData.recentAnalyses.prefix(3))
    @Published var statusText: String = "Ready to analyze"

    func startRecordingTapped() {
    }
}
