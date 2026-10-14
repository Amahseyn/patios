//
//  HomeView.swift
//  CatIos
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var petManager: PetManager
    var onNavigateTab: ((AppTab) -> Void)? = nil

    @State private var showRecordingView = false
    @State private var showAddActivitySheet = false
    @State private var showPaywall = false

    @State private var activityTitle = ""
    @State private var activityEmoji = "🍖"
    @State private var activityCategory = "Meal"

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.spacingL) {
                    petProfileHeaderCard

                    mainAIStatusCard

                    quickActionsGrid

                    memoryTimelinePreviewSection
                }
                .padding(AppTheme.spacingM)
            }
            .fantasyScreen()
            .navigationTitle("Home")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showPaywall = true
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "crown.fill")
                                .font(.caption)
                            Text("PRO")
                                .font(.caption2.weight(.bold))
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            Capsule().fill(LinearGradient(colors: [.orange, .pink], startPoint: .leading, endPoint: .trailing))
                        )
                    }
                }
            }
            .sheet(isPresented: $showAddActivitySheet) {
                addActivityModal
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
            .navigationDestination(isPresented: $showRecordingView) {
                VoiceAnalysisView()
            }
        }
    }

    private var petProfileHeaderCard: some View {
        let pet = petManager.currentPet
        return HStack(spacing: AppTheme.spacingM) {
            ZStack {
                Circle()
                    .fill(Color(hex: pet.petColorHex).opacity(0.15))
                    .frame(width: 64, height: 64)
                Text(pet.avatarEmoji)
                    .font(.system(size: 38))
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(pet.name)
                        .font(.title2.weight(.bold))
                        .foregroundStyle(AppTheme.textPrimary)

                    Spacer()

                    Menu {
                        ForEach(petManager.pets) { p in
                            Button {
                                withAnimation {
                                    petManager.selectPet(id: p.id)
                                }
                            } label: {
                                HStack {
                                    Text("\(p.avatarEmoji) \(p.name)")
                                    if p.id == pet.id {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                        Divider()
                        NavigationLink(destination: MultiPetView()) {
                            Label("Manage Pets", systemImage: "pawprint.fill")
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text("Switch")
                                .font(.caption.weight(.semibold))
                            Image(systemName: "chevron.up.chevron.down")
                                .font(.caption2)
                        }
                        .foregroundStyle(AppTheme.primary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(AppTheme.primary.opacity(0.1))
                        .clipShape(Capsule())
                    }
                }

                    Text("\(pet.breed) • \(pet.age.displayText)")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textSecondary)
            }
        }
        .padding(AppTheme.spacingM)
        .cardStyle()
    }

    private var mainAIStatusCard: some View {
        let pet = petManager.currentPet
        return VStack(alignment: .leading, spacing: AppTheme.spacingM) {
            HStack {
                Label("Today's Mood", systemImage: "sparkles")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.primary)

                Spacer()

                HStack(spacing: 4) {
                    Image(systemName: "brain.head.profile")
                    Text("\(pet.moodConfidence)% confidence")
                }
                .font(.caption.weight(.medium))
                .foregroundStyle(AppTheme.textSecondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(AppTheme.background)
                .clipShape(Capsule())
            }

            HStack(spacing: AppTheme.spacingM) {
                Text(pet.todayMoodEmoji)
                    .font(.system(size: 50))
                    .scaleEffect(1.05)

                VStack(alignment: .leading, spacing: 4) {
                    Text(pet.todayMoodTitle)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.textPrimary)

                    HStack(spacing: 4) {
                        Image(systemName: pet.isTrendPositive ? "arrow.up.right" : "arrow.down.right")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(pet.isTrendPositive ? AppTheme.success : AppTheme.danger)

                        Text("Mood trend:")
                            .font(.caption)
                            .foregroundStyle(AppTheme.textSecondary)

                        Text("\(pet.isTrendPositive ? "↑" : "↓") \(pet.moodTrendPercentage)% compared to last week")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(pet.isTrendPositive ? AppTheme.success : AppTheme.danger)
                    }
                }
            }

            Divider()
                .padding(.vertical, 2)

            HStack {
                Image(systemName: "quote.bubble.fill")
                    .foregroundStyle(AppTheme.primary)
                    .font(.caption)
                Text("\"\(pet.name) sounds relaxed and comfortable today based on recent activity.\"")
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
            }
        }
        .padding(AppTheme.spacingM)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadiusMedium, style: .continuous)
                .fill(AppTheme.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.cornerRadiusMedium)
                        .stroke(AppTheme.primary.opacity(0.2), lineWidth: 1.5)
                )
        )
        .cardShadow()
    }

    private var quickActionsGrid: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacingS) {
            Text("Quick Actions")
                .font(.headline)
                .foregroundStyle(AppTheme.textPrimary)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AppTheme.spacingM) {
                QuickActionButton(
                    icon: "person.crop.circle.fill",
                    title: "Pet Profile",
                    subtitle: "Manage profile",
                    color: AppTheme.lilac
                ) {
                    onNavigateTab?(.profile)
                }

                QuickActionButton(
                    icon: "sparkles",
                    title: "AI Assistant",
                    subtitle: "Ask care AI",
                    color: AppTheme.assistant
                ) {
                    onNavigateTab?(.aiAssistant)
                }

                QuickActionButton(
                    icon: "plus.circle.fill",
                    title: "Add Activity",
                    subtitle: "Log event",
                    color: AppTheme.honey
                ) {
                    showAddActivitySheet = true
                }

                QuickActionButton(
                    icon: "heart.text.square.fill",
                    title: "Smart Care",
                    subtitle: "Care & Reminders",
                    color: AppTheme.health
                ) {
                    onNavigateTab?(.careLog)
                }
            }
        }
    }

    private var memoryTimelinePreviewSection: some View {
        let pet = petManager.currentPet
        return VStack(alignment: .leading, spacing: AppTheme.spacingM) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(pet.name)'s Memory")
                        .font(.headline)
                        .foregroundStyle(AppTheme.textPrimary)
                    Text("Today's AI Timeline")
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                }
                Spacer()
                Button {
                    onNavigateTab?(.healthMemories)
                } label: {
                    Text("Full History")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppTheme.primary)
                }
            }

            VStack(spacing: AppTheme.spacingS) {
                ForEach(pet.memories.prefix(4)) { item in
                    HStack(spacing: AppTheme.spacingM) {
                        Text(item.time)
                            .font(.caption.weight(.bold))
                            .foregroundStyle(AppTheme.textSecondary)
                            .frame(width: 50, alignment: .leading)

                        Circle()
                            .fill(AppTheme.primary)
                            .frame(width: 8, height: 8)

                        Text(item.emoji)
                            .font(.title3)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.title)
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(AppTheme.textPrimary)
                            Text(item.category)
                                .font(.caption2)
                                .foregroundStyle(AppTheme.textSecondary)
                        }

                        Spacer()
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, AppTheme.spacingM)
                    .background(AppTheme.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadiusSmall))
                }
            }
        }
    }

    private var addActivityModal: some View {
        NavigationStack {
            Form {
                Section("Activity Details") {
                    TextField("Activity Title (e.g. Snack, Play)", text: $activityTitle)

                    Picker("Category", selection: $activityCategory) {
                        Text("Meal").tag("Meal")
                        Text("Sound").tag("Sound")
                        Text("Rest").tag("Rest")
                        Text("Activity").tag("Activity")
                        Text("Behavior").tag("Behavior")
                    }

                    Picker("Emoji Icon", selection: $activityEmoji) {
                        Text("🍖 Food").tag("🍖")
                        Text("😊 Happy").tag("😊")
                        Text("😴 Rest").tag("😴")
                        Text("🎮 Play").tag("🎮")
                        Text("🎾 Toy").tag("🎾")
                        Text("💊 Meds").tag("💊")
                    }
                }
            }
            .navigationTitle("Add Activity Log")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showAddActivitySheet = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let titleToSave = activityTitle.isEmpty ? "Logged Activity" : activityTitle
                        let formatter = DateFormatter()
                        formatter.dateFormat = "HH:mm"
                        let timeString = formatter.string(from: Date())

                        petManager.addMemoryToCurrentPet(
                            time: timeString,
                            title: titleToSave,
                            emoji: activityEmoji,
                            category: activityCategory
                        )
                        activityTitle = ""
                        showAddActivitySheet = false
                    }
                    .font(.body.weight(.bold))
                }
            }
        }
        .presentationDetents([.medium])
    }
}

struct QuickActionButton: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: AppTheme.spacingS) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 44, height: 44)
                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundStyle(color)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppTheme.textPrimary)
                        .lineLimit(1)
                    Text(subtitle)
                        .font(.caption2)
                        .foregroundStyle(AppTheme.textSecondary)
                }
                Spacer(minLength: 0)
            }
            .padding(AppTheme.spacingS)
            .cardStyle()
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    HomeView()
        .environmentObject(PetManager.shared)
}
