import SwiftUI

enum AppTab: Int, CaseIterable, Identifiable, Hashable {
    case home = 0
    case careLog = 1
    case healthMemories = 2
    case aiAssistant = 3
    case profile = 4

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .home: return L("Home")
        case .careLog: return L("Care")
        case .healthMemories: return L("Health")
        case .aiAssistant: return L("Assist")
        case .profile: return L("You")
        }
    }

    var systemImage: String {
        switch self {
        case .home: return "house.fill"
        case .careLog: return "checkmark.circle.fill"
        case .healthMemories: return "cross.case.fill"
        case .aiAssistant: return "bubble.left.and.bubble.right.fill"
        case .profile: return "person.crop.circle.fill"
        }
    }
}

struct MainTabView: View {
    @StateObject private var petManager = PetManager.shared
    @StateObject private var taskStore = CareTaskStore.shared
    @StateObject private var healthStore = HealthRecordStore.shared
    @StateObject private var authSession = AuthSession.shared
    @StateObject private var householdSync = HouseholdSync.shared
    @StateObject private var assistantSessions = AssistantSessionStore.shared
    @StateObject private var membership = MembershipStore.shared
    @StateObject private var wellness = WellnessStore.shared
    @StateObject private var analytics = AnalyticsStore.shared
    @State private var selectedTab: AppTab = .home
    @State private var showPricing = false

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab(AppTab.home.title, systemImage: AppTab.home.systemImage, value: AppTab.home) {
                HomeOverviewView(selectedTab: $selectedTab)
            }
            Tab(AppTab.careLog.title, systemImage: AppTab.careLog.systemImage, value: AppTab.careLog) {
                CareLogHubView()
            }
            Tab(AppTab.healthMemories.title, systemImage: AppTab.healthMemories.systemImage, value: AppTab.healthMemories) {
                HealthMemoriesView()
            }
            Tab(AppTab.aiAssistant.title, systemImage: AppTab.aiAssistant.systemImage, value: AppTab.aiAssistant) {
                ProfileAIView()
            }
            Tab(AppTab.profile.title, systemImage: AppTab.profile.systemImage, value: AppTab.profile) {
                ProfileView()
            }
        }
        .tint(AppTheme.primary)
        .environmentObject(petManager)
        .environmentObject(taskStore)
        .environmentObject(healthStore)
        .environmentObject(authSession)
        .environmentObject(householdSync)
        .environmentObject(assistantSessions)
        .environmentObject(membership)
        .environmentObject(wellness)
        .environmentObject(analytics)
        .sheet(isPresented: $showPricing) {
            PaywallView()
        }
        .onAppear {
            householdSync.observeStores()
            CareReminderScheduler.shared.reschedule(tasks: taskStore.tasks)
            healthStore.applyNotificationPreference()
            Task { await householdSync.connect() }
        }
    }
}

#Preview {
    MainTabView()
}
