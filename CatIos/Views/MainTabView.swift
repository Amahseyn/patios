//
//  MainTabView.swift
//  Patios (CatIos)
//

import SwiftUI

enum AppTab: Int, CaseIterable, Identifiable {
    case home = 0
    case careLog = 1
    case healthMemories = 2
    case aiAssistant = 3
    case profile = 4

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .home: return "Home"
        case .careLog: return "Tasks"
        case .healthMemories: return "Health"
        case .aiAssistant: return "AI"
        case .profile: return "Profile"
        }
    }

    var icon: String {
        switch self {
        case .home: return "house.fill"
        case .careLog: return "heart.text.square.fill"
        case .healthMemories: return "syringe.fill"
        case .aiAssistant: return "sparkles"
        case .profile: return "person.crop.circle.fill"
        }
    }

    var accessibilityLabel: String {
        switch self {
        case .home: return "Home dashboard"
        case .careLog: return "Care tasks and reminders"
        case .healthMemories: return "Health records and vaccines"
        case .aiAssistant: return "AI pet care assistant"
        case .profile: return "Profile and settings"
        }
    }
}

struct MainTabView: View {
    @State private var selectedTab: AppTab = .home
    @StateObject private var petManager = PetManager.shared

    var body: some View {
        TabView(selection: $selectedTab) {
            PatiosHomeView(onNavigateTab: { tab in
                withAnimation(.easeInOut(duration: 0.2)) {
                    selectedTab = tab
                }
            })
            .tabItem {
                Label(AppTab.home.title, systemImage: AppTab.home.icon)
            }
            .tag(AppTab.home)
            .accessibilityLabel(AppTab.home.accessibilityLabel)

            CareLogHubView()
                .tabItem {
                    Label(AppTab.careLog.title, systemImage: AppTab.careLog.icon)
                }
                .tag(AppTab.careLog)
                .accessibilityLabel(AppTab.careLog.accessibilityLabel)

            HealthMemoriesView()
                .tabItem {
                    Label(AppTab.healthMemories.title, systemImage: AppTab.healthMemories.icon)
                }
                .tag(AppTab.healthMemories)
                .accessibilityLabel(AppTab.healthMemories.accessibilityLabel)

            ProfileAIView()
                .tabItem {
                    Label(AppTab.aiAssistant.title, systemImage: AppTab.aiAssistant.icon)
                }
                .tag(AppTab.aiAssistant)
                .accessibilityLabel(AppTab.aiAssistant.accessibilityLabel)

            ProfileView()
                .tabItem {
                    Label(AppTab.profile.title, systemImage: AppTab.profile.icon)
                }
                .tag(AppTab.profile)
                .accessibilityLabel(AppTab.profile.accessibilityLabel)
        }
        .tint(AppTheme.primary)
        .environmentObject(petManager)
    }
}

#Preview {
    MainTabView()
}
