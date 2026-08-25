//
//  SettingsViewModel.swift
//  CatEmotionAI
//

import SwiftUI
import Combine

@MainActor
final class SettingsViewModel: ObservableObject {
    @Published var notificationsEnabled: Bool = true {
        didSet {
            if !notificationsEnabled {
                taskRemindersEnabled = false
                healthAlertsEnabled = false
                aiSuggestionsEnabled = false
            }
        }
    }
    @Published var taskRemindersEnabled: Bool = true
    @Published var healthAlertsEnabled: Bool = true
    @Published var aiSuggestionsEnabled: Bool = true
    @Published var darkModeEnabled: Bool = false
}
