//
//  SettingsViewModel.swift
//  CatEmotionAI
//

import SwiftUI
import Combine

enum NotificationPreferences {
    static let masterKey = "notificationsEnabled"
    static let tasksKey = "taskRemindersEnabled"
    static let healthKey = "healthAlertsEnabled"
    static let assistantKey = "aiSuggestionsEnabled"

    static func isOn(_ key: String, default value: Bool = true) -> Bool {
        UserDefaults.standard.object(forKey: key) as? Bool ?? value
    }
}

@MainActor
final class SettingsViewModel: ObservableObject {
    @Published var notificationsEnabled: Bool = true {
        didSet {
            guard isReady, notificationsEnabled != oldValue else { return }
            taskRemindersEnabled = notificationsEnabled
            healthAlertsEnabled = notificationsEnabled
            aiSuggestionsEnabled = notificationsEnabled
            persistAndApply()
        }
    }
    @Published var taskRemindersEnabled: Bool = true {
        didSet { persistAndApply() }
    }
    @Published var healthAlertsEnabled: Bool = true {
        didSet { persistAndApply() }
    }
    @Published var aiSuggestionsEnabled: Bool = true {
        didSet { persistAndApply() }
    }

    private var isReady = false

    init() {
        notificationsEnabled = NotificationPreferences.isOn(NotificationPreferences.masterKey)
        taskRemindersEnabled = NotificationPreferences.isOn(NotificationPreferences.tasksKey)
        healthAlertsEnabled = NotificationPreferences.isOn(NotificationPreferences.healthKey)
        aiSuggestionsEnabled = NotificationPreferences.isOn(NotificationPreferences.assistantKey)
        isReady = true
    }

    private func persistAndApply() {
        guard isReady else { return }
        let defaults = UserDefaults.standard
        defaults.set(notificationsEnabled, forKey: NotificationPreferences.masterKey)
        defaults.set(taskRemindersEnabled, forKey: NotificationPreferences.tasksKey)
        defaults.set(healthAlertsEnabled, forKey: NotificationPreferences.healthKey)
        defaults.set(aiSuggestionsEnabled, forKey: NotificationPreferences.assistantKey)
        CareReminderScheduler.shared.reschedule(tasks: CareTaskStore.shared.tasks)
        HealthRecordStore.shared.applyNotificationPreference()
    }
}
