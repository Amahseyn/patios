//
//  HomeOverviewView.swift
//  CatIos — owner home dashboard
//

import SwiftUI

struct HomeOverviewView: View {
    @Binding var selectedTab: AppTab
    @EnvironmentObject private var petManager: PetManager
    @EnvironmentObject private var taskStore: CareTaskStore
    @EnvironmentObject private var healthStore: HealthRecordStore
    @EnvironmentObject private var householdSync: HouseholdSync
    @EnvironmentObject private var authSession: AuthSession
    @EnvironmentObject private var membership: MembershipStore

    @State private var showAddPet = false
    @State private var showPaywall = false

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return L("Good morning")
        case 12..<17: return L("Good afternoon")
        case 17..<22: return L("Good evening")
        default: return L("Hello")
        }
    }

    private var todayTasks: [CustomCareTask] {
        taskStore.tasks.filter { taskAppliesToday($0) }
    }

    private var completedTodayCount: Int {
        todayTasks.filter { isCompletedToday($0) }.count
    }

    private var remainingTodayCount: Int {
        max(0, todayTasks.count - completedTodayCount)
    }

    private var todayProgress: Double {
        guard !todayTasks.isEmpty else { return 0 }
        return Double(completedTodayCount) / Double(todayTasks.count)
    }

    private var upcomingHealth: [HealthRecord] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let horizon = calendar.date(byAdding: .day, value: 21, to: today) ?? today
        return healthStore.records
            .filter { record in
                guard let due = record.nextDueDate else { return false }
                return calendar.startOfDay(for: due) <= horizon
            }
            .sorted { ($0.nextDueDate ?? .distantFuture) < ($1.nextDueDate ?? .distantFuture) }
            .prefix(3)
            .map { $0 }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppTheme.spacingL) {
                    if householdSync.lastError != nil {
                        SyncStatusBanner()
                    }

                    greetingHeader

                    if petManager.pets.isEmpty {
                        EmptyStateView(
                            systemImage: "pawprint.fill",
                            title: "Add your first pet",
                            message: "Profiles, daily tasks, and health records all start with a pet.",
                            actionTitle: "Add Pet",
                            action: { showAddPet = true }
                        )
                        .cardStyle(cornerRadius: AppTheme.cornerRadiusLarge)
                    } else {
                        petStrip
                        careProgressCard
                        if !upcomingHealth.isEmpty {
                            upcomingHealthCard
                        }
                        quickActions
                        tipsCard
                    }
                }
                .padding(AppTheme.spacingM)
            }
            .fantasyScreen()
            .fantasyNavigation()
            .navigationTitle("Home")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showPaywall = true
                    } label: {
                        Label(
                            membership.plan == .basic ? L("Upgrade") : "Pet Care+",
                            systemImage: "star.fill"
                        )
                        .font(AppTheme.captionFont().weight(.bold))
                        .foregroundStyle(membership.plan == .basic ? AppTheme.starlight : AppTheme.primary)
                    }
                    .accessibilityLabel("Membership")
                }
            }
            .sheet(isPresented: $showAddPet) {
                AddPetModalView()
                    .environmentObject(petManager)
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
            .refreshable {
                await householdSync.pullNow()
            }
        }
    }

    private var greetingHeader: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacingS) {
            Text(greeting)
                .font(AppTheme.captionFont().weight(.semibold))
                .foregroundStyle(AppTheme.primary)
                .textCase(.uppercase)
            Text(ownerTitle)
                .font(AppTheme.titleFont(28))
                .foregroundStyle(AppTheme.textPrimary)
                .accessibilityAddTraits(.isHeader)
            Text(subtitleLine)
                .font(AppTheme.bodyFont())
                .foregroundStyle(AppTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    private var ownerTitle: String {
        if petManager.pets.count == 1 {
            return LF("%@’s day", petManager.currentPet.name)
        }
        if petManager.pets.isEmpty {
            return L("Your pet home")
        }
        return L("Your pets today")
    }

    private var subtitleLine: String {
        if petManager.pets.isEmpty {
            return L("Set up a profile to track meals, walks, meds, and vet visits.")
        }
        if remainingTodayCount == 0 && !todayTasks.isEmpty {
            return L("All of today’s care tasks are done. Nice work.")
        }
        if todayTasks.isEmpty {
            return L("No tasks scheduled for today — add one from Care when you’re ready.")
        }
        return LF("%lld care tasks left · %lld pets", remainingTodayCount, petManager.pets.count)
    }

    private var petStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppTheme.spacingS) {
                ForEach(petManager.pets) { pet in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            petManager.selectPet(id: pet.id)
                        }
                    } label: {
                        VStack(spacing: 6) {
                            ZStack {
                                Circle()
                                    .fill(Color(hex: pet.petColorHex).opacity(0.18))
                                    .frame(width: 56, height: 56)
                                Text(pet.avatarEmoji)
                                    .font(.title2)
                            }
                            .overlay {
                                Circle()
                                    .strokeBorder(
                                        pet.id == petManager.selectedPetId ? AppTheme.primary : Color.clear,
                                        lineWidth: 2
                                    )
                            }
                            Text(pet.name)
                                .font(AppTheme.captionFont().weight(.semibold))
                                .foregroundStyle(
                                    pet.id == petManager.selectedPetId ? AppTheme.primary : AppTheme.textSecondary
                                )
                                .lineLimit(1)
                        }
                        .frame(width: 72)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(Text(verbatim: pet.name))
                    .accessibilityAddTraits(pet.id == petManager.selectedPetId ? .isSelected : [])
                }
            }
            .padding(.vertical, 2)
        }
    }

    private var careProgressCard: some View {
        Button {
            selectedTab = .careLog
        } label: {
            VStack(alignment: .leading, spacing: AppTheme.spacingM) {
                HStack {
                    EnchantedIconBadge(systemImage: "checkmark.circle.fill", tint: AppTheme.tasks, size: 40)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Today’s care")
                            .font(AppTheme.headlineFont())
                            .foregroundStyle(AppTheme.textPrimary)
                        Text(todayTasks.isEmpty ? L("No tasks yet") : LF("%lld of %lld done", completedTodayCount, todayTasks.count))
                            .font(AppTheme.captionFont())
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.forward")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AppTheme.textSecondary)
                }

                if !todayTasks.isEmpty {
                    ProgressView(value: todayProgress)
                        .tint(remainingTodayCount == 0 ? AppTheme.success : AppTheme.primary)
                    HStack {
                        Label("\(remainingTodayCount) left", systemImage: "circle")
                            .font(AppTheme.captionFont().weight(.medium))
                            .foregroundStyle(AppTheme.textSecondary)
                        Spacer()
                        Text(remainingTodayCount == 0 ? L("All clear") : L("Open Care"))
                            .font(AppTheme.captionFont().weight(.semibold))
                            .foregroundStyle(AppTheme.primary)
                    }
                } else {
                    Text("Tap to add feeding, walks, meds, and more.")
                        .font(AppTheme.captionFont())
                        .foregroundStyle(AppTheme.textSecondary)
                }
            }
            .padding(AppTheme.spacingM)
            .cardStyle(cornerRadius: AppTheme.cornerRadiusLarge)
        }
        .buttonStyle(PressableButtonStyle())
        .accessibilityHint("Opens the Care tab")
    }

    private var upcomingHealthCard: some View {
        Button {
            selectedTab = .healthMemories
        } label: {
            VStack(alignment: .leading, spacing: AppTheme.spacingS) {
                HStack {
                    EnchantedIconBadge(systemImage: "cross.case.fill", tint: AppTheme.health, size: 40)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Coming up in health")
                            .font(AppTheme.headlineFont())
                            .foregroundStyle(AppTheme.textPrimary)
                        Text("Next 3 weeks")
                            .font(AppTheme.captionFont())
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.forward")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AppTheme.textSecondary)
                }

                ForEach(upcomingHealth) { record in
                    HStack(spacing: AppTheme.spacingS) {
                        Circle()
                            .fill(dueTint(for: record).opacity(0.9))
                            .frame(width: 8, height: 8)
                        Text(LocalizedStringKey(record.title))
                            .font(AppTheme.bodyFont().weight(.medium))
                            .foregroundStyle(AppTheme.textPrimary)
                            .lineLimit(1)
                        Spacer(minLength: 4)
                        if let due = record.nextDueDate {
                            Text(due, style: .date)
                                .font(AppTheme.captionFont())
                                .foregroundStyle(dueTint(for: record))
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .padding(AppTheme.spacingM)
            .cardStyle(cornerRadius: AppTheme.cornerRadiusLarge)
        }
        .buttonStyle(PressableButtonStyle())
        .accessibilityHint("Opens the Health tab")
    }

    private var quickActions: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacingS) {
            FantasySectionHeader(title: "Quick actions", subtitle: "Jump to what you need")

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AppTheme.spacingM) {
                HomeQuickAction(
                    title: "Care tasks",
                    subtitle: "Mark done",
                    systemImage: "checklist",
                    tint: AppTheme.tasks
                ) { selectedTab = .careLog }

                HomeQuickAction(
                    title: "Health",
                    subtitle: "Records & due dates",
                    systemImage: "cross.case.fill",
                    tint: AppTheme.health
                ) { selectedTab = .healthMemories }

                HomeQuickAction(
                    title: "Assistant",
                    subtitle: "Ask care AI",
                    systemImage: "bubble.left.and.bubble.right.fill",
                    tint: AppTheme.assistant
                ) { selectedTab = .aiAssistant }

                HomeQuickAction(
                    title: "Pets & you",
                    subtitle: "Profiles & sync",
                    systemImage: "person.crop.circle.fill",
                    tint: AppTheme.meadow
                ) { selectedTab = .profile }
            }
        }
    }

    private var tipsCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacingS) {
            Label("Owner tip", systemImage: "lightbulb.fill")
                .font(AppTheme.headlineFont())
                .foregroundStyle(AppTheme.honey)
            Text(ownerTip)
                .font(AppTheme.bodyFont())
                .foregroundStyle(AppTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(AppTheme.spacingM)
        .cardStyle(cornerRadius: AppTheme.cornerRadiusLarge)
        .accessibilityElement(children: .combine)
    }

    private var ownerTip: String {
        if !authSession.isSignedIn {
            return L("Sign in from You to back up pets, tasks, and health records across devices.")
        }
        if todayTasks.isEmpty {
            return L("Use Care → Add to schedule daily feeding and weekly grooming so nothing slips.")
        }
        return L("Swipe a care task to snooze or edit. Health reminders keep vaccines and vet visits on track.")
    }

    private func dueTint(for record: HealthRecord) -> Color {
        guard let due = record.nextDueDate else { return AppTheme.textSecondary }
        let today = Calendar.current.startOfDay(for: Date())
        let dueDay = Calendar.current.startOfDay(for: due)
        if dueDay < today { return AppTheme.danger }
        if dueDay == today { return AppTheme.warning }
        return AppTheme.health
    }

    private func taskAppliesToday(_ task: CustomCareTask) -> Bool {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: Date())
        switch task.frequency {
        case .hourly, .daily:
            return true
        case .weekly:
            return task.selectedDays.contains(weekday)
        case .monthly, .yearly, .custom:
            return true
        }
    }

    private func isCompletedToday(_ task: CustomCareTask) -> Bool {
        if task.petId == PetManager.allPetsId {
            return petManager.pets.allSatisfy { task.completedPetDateOffsets[$0.id] == 0 }
                || (task.isCompleted && task.completedDateOffset == 0)
        }
        return task.completedPetDateOffsets[task.petId] == 0
            || (task.isCompleted && task.completedDateOffset == 0)
    }
}

private struct HomeQuickAction: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let tint: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: AppTheme.spacingS) {
                EnchantedIconBadge(systemImage: systemImage, tint: tint, size: 40)
                VStack(alignment: .leading, spacing: 2) {
                    Text(LocalizedStringKey(title))
                        .font(AppTheme.bodyFont().weight(.semibold))
                        .foregroundStyle(AppTheme.textPrimary)
                        .lineLimit(1)
                    Text(LocalizedStringKey(subtitle))
                        .font(AppTheme.captionFont())
                        .foregroundStyle(AppTheme.textSecondary)
                        .lineLimit(1)
                }
                Spacer(minLength: 0)
            }
            .padding(AppTheme.spacingS)
            .cardStyle()
        }
        .buttonStyle(PressableButtonStyle())
    }
}

#Preview {
    HomeOverviewView(selectedTab: .constant(.home))
        .environmentObject(PetManager.shared)
        .environmentObject(CareTaskStore.shared)
        .environmentObject(HealthRecordStore.shared)
        .environmentObject(HouseholdSync.shared)
        .environmentObject(AuthSession.shared)
        .environmentObject(MembershipStore.shared)
}
