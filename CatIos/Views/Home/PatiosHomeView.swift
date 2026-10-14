//
//  PatiosHomeView.swift
//  Patios (CatIos)
//
//  Owner home: pet context, voice scan CTA, mood snapshot, and quick navigation.
//

import SwiftUI

struct PatiosHomeView: View {
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

                    RecordHeroCard(
                        statusText: "Tap to scan \(petManager.currentPet.name)'s voice",
                        onTap: { showRecordingView = true }
                    )
                    .accessibilityHint("Opens voice emotion analysis")

                    mainAIStatusCard

                    quickActionsGrid

                    memoryTimelinePreviewSection
                }
                .padding(AppTheme.spacingM)
            }
            .patiosScreenBackground()
            .navigationTitle("Patios")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    ProBadgeButton { showPaywall = true }
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
            .accessibilityLabel("\(pet.name) profile")

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(pet.name)
                        .font(AppTypography.title2)
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
                        NavigationLink(destination: PetManagementView()) {
                            Label("Manage Pets", systemImage: "pawprint.fill")
                        }
                    } label: {
                        Label("Switch pet", systemImage: "chevron.up.chevron.down")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(AppTheme.primary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(AppTheme.primary.opacity(0.1))
                            .clipShape(Capsule())
                    }
                }

                Text("\(pet.breed) • \(pet.age.displayText)")
                    .font(AppTypography.subheadline)
                    .foregroundStyle(AppTheme.textSecondary)

                HStack(spacing: 6) {
                    Image(systemName: "heart.fill")
                        .font(.caption2)
                        .foregroundStyle(AppTheme.success)
                    Text("Wellness \(pet.wellnessScore)%")
                        .font(AppTypography.caption.weight(.semibold))
                        .foregroundStyle(AppTheme.textSecondary)
                }
            }
        }
        .padding(AppTheme.spacingM)
        .cardStyle()
    }

    private var mainAIStatusCard: some View {
        let pet = petManager.currentPet
        return VStack(alignment: .leading, spacing: AppTheme.spacingM) {
            HStack {
                Label("Today's mood", systemImage: "sparkles")
                    .font(AppTypography.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.primary)

                Spacer()

                HStack(spacing: 4) {
                    Image(systemName: "brain.head.profile")
                    Text("\(pet.moodConfidence)% confidence")
                }
                .font(AppTypography.caption)
                .foregroundStyle(AppTheme.textSecondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(AppTheme.background)
                .clipShape(Capsule())
            }

            HStack(spacing: AppTheme.spacingM) {
                Text(pet.todayMoodEmoji)
                    .font(.system(size: 50))
                    .accessibilityLabel(pet.todayMoodTitle)

                VStack(alignment: .leading, spacing: 4) {
                    Text(pet.todayMoodTitle)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.textPrimary)

                    HStack(spacing: 4) {
                        Image(systemName: pet.isTrendPositive ? "arrow.up.right" : "arrow.down.right")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(pet.isTrendPositive ? AppTheme.success : AppTheme.danger)

                        Text("Mood trend:")
                            .font(AppTypography.caption)
                            .foregroundStyle(AppTheme.textSecondary)

                        Text("\(pet.isTrendPositive ? "↑" : "↓") \(pet.moodTrendPercentage)% vs last week")
                            .font(AppTypography.caption.weight(.semibold))
                            .foregroundStyle(pet.isTrendPositive ? AppTheme.success : AppTheme.danger)
                    }
                }
            }

            Divider()
                .padding(.vertical, 2)

            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "quote.bubble.fill")
                    .foregroundStyle(AppTheme.primary)
                    .font(.caption)
                Text("\"\(pet.name) sounds relaxed and comfortable today based on recent activity.\"")
                    .font(AppTypography.caption)
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
            SectionHeader(title: "Quick actions")

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AppTheme.spacingM) {
                QuickActionButton(
                    icon: "heart.text.square.fill",
                    title: "Care tasks",
                    subtitle: "Today's schedule",
                    color: AppTheme.primary
                ) {
                    onNavigateTab?(.careLog)
                }

                QuickActionButton(
                    icon: "syringe.fill",
                    title: "Health",
                    subtitle: "Vaccines & vet",
                    color: Color.purple
                ) {
                    onNavigateTab?(.healthMemories)
                }

                QuickActionButton(
                    icon: "sparkles",
                    title: "AI assistant",
                    subtitle: "Ask Patios AI",
                    color: Color.indigo
                ) {
                    onNavigateTab?(.aiAssistant)
                }

                QuickActionButton(
                    icon: "plus.circle.fill",
                    title: "Log activity",
                    subtitle: "Meal, play, rest",
                    color: AppTheme.secondary
                ) {
                    showAddActivitySheet = true
                }
            }
        }
    }

    private var memoryTimelinePreviewSection: some View {
        let pet = petManager.currentPet
        return VStack(alignment: .leading, spacing: AppTheme.spacingM) {
            SectionHeader(
                title: "\(pet.name)'s timeline",
                subtitle: "Recent moments",
                trailingTitle: pet.memories.isEmpty ? nil : "See all",
                trailingAction: pet.memories.isEmpty ? nil : { onNavigateTab?(.healthMemories) }
            )

            if pet.memories.isEmpty {
                EmptyStateView(
                    systemImage: "clock.arrow.circlepath",
                    title: "No moments yet",
                    message: "Log an activity or run a voice scan to build \(pet.name)'s timeline."
                )
                .cardStyle()
            } else {
                VStack(spacing: AppTheme.spacingS) {
                    ForEach(pet.memories.prefix(4)) { item in
                        HStack(spacing: AppTheme.spacingM) {
                            Text(item.time)
                                .font(AppTypography.caption.weight(.bold))
                                .foregroundStyle(AppTheme.textSecondary)
                                .frame(width: 50, alignment: .leading)

                            Circle()
                                .fill(AppTheme.primary)
                                .frame(width: 8, height: 8)

                            Text(item.emoji)
                                .font(.title3)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.title)
                                    .font(AppTypography.subheadline.weight(.medium))
                                    .foregroundStyle(AppTheme.textPrimary)
                                Text(item.category)
                                    .font(AppTypography.caption)
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
    }

    private var addActivityModal: some View {
        NavigationStack {
            Form {
                Section("Activity details") {
                    TextField("Title (e.g. snack, play)", text: $activityTitle)

                    Picker("Category", selection: $activityCategory) {
                        Text("Meal").tag("Meal")
                        Text("Sound").tag("Sound")
                        Text("Rest").tag("Rest")
                        Text("Activity").tag("Activity")
                        Text("Behavior").tag("Behavior")
                    }

                    Picker("Icon", selection: $activityEmoji) {
                        Text("🍖 Food").tag("🍖")
                        Text("😊 Happy").tag("😊")
                        Text("😴 Rest").tag("😴")
                        Text("🎮 Play").tag("🎮")
                        Text("🎾 Toy").tag("🎾")
                        Text("💊 Meds").tag("💊")
                    }
                }
            }
            .navigationTitle("Log activity")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showAddActivitySheet = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let titleToSave = activityTitle.isEmpty ? "Logged activity" : activityTitle
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

#Preview {
    PatiosHomeView()
        .environmentObject(PetManager.shared)
}
