//
//  SettingsView.swift
//  CatEmotionAI
//
//  App settings: notifications, appearance, privacy, about.

import SwiftUI
import UserNotifications

struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()
    @AppStorage("prefersDarkMode") private var prefersDarkMode: Bool = false

    var body: some View {
        NavigationStack {
            List {
                Section("Notifications") {
                    Toggle(isOn: $viewModel.notificationsEnabled) {
                        SettingsLabel(icon: "bell.fill", tint: .orange, title: "Allow Notifications")
                    }
                    .onChange(of: viewModel.notificationsEnabled) { _, newValue in
                        if newValue {
                            requestNotificationPermission()
                        }
                    }

                    if viewModel.notificationsEnabled {
                        Toggle(isOn: $viewModel.taskRemindersEnabled) {
                            SettingsLabel(icon: "checklist", tint: .blue, title: "Task & Care Reminders")
                        }
                        Toggle(isOn: $viewModel.healthAlertsEnabled) {
                            SettingsLabel(icon: "heart.fill", tint: .red, title: "Health & Vaccination Alerts")
                        }
                        Toggle(isOn: $viewModel.aiSuggestionsEnabled) {
                            SettingsLabel(icon: "sparkles", tint: .purple, title: "AI Assistant Suggestions")
                        }
                    }
                }



                Section {
                    HStack {
                        Spacer()
                        Text("Pet Emotion AI v1.0.0 (Prototype)")
                            .font(.caption)
                            .foregroundStyle(AppTheme.textSecondary)
                        Spacer()
                    }
                }
                .listRowBackground(Color.clear)
            }
            .navigationTitle("Settings")
            .scrollContentBackground(.hidden)
            .background(AppTheme.background.ignoresSafeArea())
            .onAppear {
                checkNotificationPermission()
            }
        }
    }

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            DispatchQueue.main.async {
                if !granted {
                    viewModel.notificationsEnabled = false
                }
            }
        }
    }

    private func checkNotificationPermission() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                if settings.authorizationStatus == .denied {
                    viewModel.notificationsEnabled = false
                }
            }
        }
    }
}

private struct SettingsLabel: View {
    let icon: String
    let tint: Color
    let title: String

    var body: some View {
        HStack(spacing: AppTheme.spacingM) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(tint)
                    .frame(width: 30, height: 30)
                Image(systemName: icon)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white)
            }
            Text(title)
                .foregroundStyle(AppTheme.textPrimary)
        }
    }
}

private struct AboutView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.spacingM) {
                ZStack {
                    RoundedRectangle(cornerRadius: AppTheme.cornerRadiusMedium, style: .continuous)
                        .fill(AppTheme.heroGradient)
                        .frame(width: 88, height: 88)
                    Image("AppLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 60, height: 60)
                }
                .padding(.top, AppTheme.spacingL)

                Text("Pet Emotion AI")
                    .font(.title2.weight(.bold))
                Text("Understand your pet's emotions through the sound of their voice.")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AppTheme.spacingL)

                Text("Version 1.0.0 (Prototype)")
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
                    .padding(.top, AppTheme.spacingM)
            }
            .padding()
        }
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
        .background(AppTheme.background.ignoresSafeArea())
    }
}

#Preview {
    SettingsView()
}
