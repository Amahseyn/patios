//
//  MainTabView.swift
//  CatIos
//

import SwiftUI

enum AppTab: Int, CaseIterable, Identifiable {
    case careLog = 0
    case healthMemories = 1
    case aiAssistant = 2
    case profile = 3

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .careLog: return "Tasks"
        case .healthMemories: return "Health"
        case .aiAssistant: return "AI Assistant"
        case .profile: return "Profile"
        }
    }

    var icon: String {
        switch self {
        case .careLog: return "heart.text.square.fill"
        case .healthMemories: return "syringe.fill"
        case .aiAssistant: return "sparkles"
        case .profile: return "person.crop.circle.fill"
        }
    }
}

struct MainTabView: View {
    @State private var selectedTab: AppTab = .careLog
    @StateObject private var petManager = PetManager.shared

    var body: some View {
        TabView(selection: $selectedTab) {
            CareLogHubView()
            .tabItem {
                Label(AppTab.careLog.title, systemImage: AppTab.careLog.icon)
            }
            .tag(AppTab.careLog)

            HealthMemoriesView()
            .tabItem {
                Label(AppTab.healthMemories.title, systemImage: AppTab.healthMemories.icon)
            }
            .tag(AppTab.healthMemories)

            ProfileAIView()
            .tabItem {
                Label(AppTab.aiAssistant.title, systemImage: AppTab.aiAssistant.icon)
            }
            .tag(AppTab.aiAssistant)

            ProfileView()
            .tabItem {
                Label(AppTab.profile.title, systemImage: AppTab.profile.icon)
            }
            .tag(AppTab.profile)
        }
        .environmentObject(petManager)
    }
}

#Preview {
    MainTabView()
}
