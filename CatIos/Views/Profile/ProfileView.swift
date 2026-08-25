//
//  ProfileView.swift
//  CatEmotionAI
//

import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var petManager: PetManager
    @State private var showPaywall = false
    @AppStorage("prefersDarkMode") private var prefersDarkMode: Bool = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.spacingL) {
                    VStack(spacing: AppTheme.spacingS) {
                        NavigationLink {
                            PetManagementView()
                        } label: {
                            SettingsRow(icon: "pawprint.fill", title: "Manage Pets & Profiles", subtitle: "\(petManager.pets.count) registered • Edit, add, remove", color: .orange)
                        }
                        .buttonStyle(.plain)

                        NavigationLink {
                            PrivacyPolicyView()
                        } label: {
                            SettingsRow(icon: "lock.fill", title: "Privacy Policy", subtitle: "How we protect your data", color: .green)
                        }
                        .buttonStyle(.plain)

                        NavigationLink {
                            TermsOfUseView()
                        } label: {
                            SettingsRow(icon: "doc.text.fill", title: "Terms of Use", subtitle: "App usage terms and conditions", color: .blue)
                        }
                        .buttonStyle(.plain)

                        NavigationLink {
                            SettingsView()
                        } label: {
                            SettingsRow(icon: "bell.fill", title: "Notifications", subtitle: "Task, health, and AI alerts", color: .orange)
                        }
                        .buttonStyle(.plain)

                        Button {
                            showPaywall = true
                        } label: {
                            SettingsRow(icon: "crown.fill", title: "Upgrade to PRO", subtitle: "Unlimited AI analyses & multi-user sync", color: .pink)
                        }
                        .buttonStyle(.plain)

                        Toggle(isOn: $prefersDarkMode) {
                            HStack(spacing: AppTheme.spacingM) {
                                ZStack {
                                    Circle()
                                        .fill(Color.blue.opacity(0.15))
                                        .frame(width: 36, height: 36)
                                    Image(systemName: "moon.fill")
                                        .foregroundStyle(Color.blue)
                                }
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Dark Mode")
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(AppTheme.textPrimary)
                                    Text("Toggle application theme")
                                        .font(.caption2)
                                        .foregroundStyle(AppTheme.textSecondary)
                                }
                            }
                        }
                        .padding(AppTheme.spacingM)
                        .cardStyle()
                    }
                }
                .padding(AppTheme.spacingM)
            }
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct SettingsRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color

    var body: some View {
        HStack(spacing: AppTheme.spacingM) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .foregroundStyle(color)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.textPrimary)
                Text(subtitle)
                    .font(.caption2)
                    .foregroundStyle(AppTheme.textSecondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption.weight(.bold))
                .foregroundStyle(AppTheme.textSecondary)
        }
        .padding(AppTheme.spacingM)
        .cardStyle()
    }
}
