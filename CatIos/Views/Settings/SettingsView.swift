//
//  SettingsView.swift
//  CatEmotionAI
//

import SwiftUI
import UserNotifications

struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()
    @State private var authorization = UNAuthorizationStatus.notDetermined

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.spacingL) {
                RealmProfileHero(
                    title: "Notifications",
                    subtitle: "Choose which reminders this iPhone sends.",
                    systemImage: "bell.badge.fill"
                )

                RealmSectionCard(title: "Notifications", subtitle: "Care & health alerts", icon: "bell.fill", tint: AppTheme.honey) {
                    Toggle(isOn: $viewModel.notificationsEnabled) {
                        realmToggleLabel("Allow notifications", icon: "bell")
                    }
                    .padding(.horizontal, AppTheme.spacingS)
                    .padding(.vertical, 8)
                    .onChange(of: viewModel.notificationsEnabled) { _, newValue in
                        if newValue {
                            requestNotificationPermission()
                        }
                    }

                    if viewModel.notificationsEnabled {
                        RealmRowDivider()
                        Toggle(isOn: $viewModel.taskRemindersEnabled) {
                            realmToggleLabel("Task reminders", icon: "checkmark.circle")
                        }
                        .padding(.horizontal, AppTheme.spacingS)
                        .padding(.vertical, 8)

                        RealmRowDivider()
                        Toggle(isOn: $viewModel.healthAlertsEnabled) {
                            realmToggleLabel("Health due dates", icon: "heart.fill")
                        }
                        .padding(.horizontal, AppTheme.spacingS)
                        .padding(.vertical, 8)

                        RealmRowDivider()
                        Toggle(isOn: $viewModel.aiSuggestionsEnabled) {
                            realmToggleLabel("Assistant suggestions", icon: "bubble.left.and.bubble.right")
                        }
                        .padding(.horizontal, AppTheme.spacingS)
                        .padding(.vertical, 8)
                    }

                    Text(footerText)
                        .font(AppTheme.captionFont())
                        .foregroundStyle(AppTheme.textSecondary)
                        .padding(.horizontal, AppTheme.spacingS)
                        .padding(.top, 4)
                        .padding(.bottom, 8)
                }

                if authorization == .denied {
                    RealmSectionCard(title: "System settings", icon: "gear", tint: AppTheme.warning) {
                        RealmActionRow(
                            title: "Open iOS Settings",
                            subtitle: "Enable notifications for Pet Care",
                            icon: "arrow.up.forward.app",
                            tint: AppTheme.warning
                        ) {
                            if let url = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(url)
                            }
                        }
                    }
                }
            }
            .padding(AppTheme.spacingM)
        }
        .fantasyScreen()
        .navigationTitle("Notifications")
        .fantasyNavigation()
        .onAppear {
            checkNotificationPermission()
        }
    }

    private var footerText: String {
        if authorization == .denied {
            return "Notifications are off for Pet Care in iOS Settings."
        }
        return "Task alarms and health due dates are scheduled on this iPhone."
    }

    private func realmToggleLabel(_ title: String, icon: String) -> some View {
        Label(title, systemImage: icon)
            .font(AppTheme.bodyFont().weight(.medium))
            .foregroundStyle(AppTheme.textPrimary)
    }

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
            DispatchQueue.main.async {
                authorization = granted ? .authorized : .denied
                if !granted {
                    viewModel.notificationsEnabled = false
                } else {
                    CareReminderScheduler.shared.reschedule(tasks: CareTaskStore.shared.tasks)
                    HealthRecordStore.shared.applyNotificationPreference()
                }
            }
        }
    }

    private func checkNotificationPermission() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                authorization = settings.authorizationStatus
                if settings.authorizationStatus == .denied {
                    viewModel.notificationsEnabled = false
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
}
