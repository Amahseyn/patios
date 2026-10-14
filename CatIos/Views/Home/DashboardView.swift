//
//  DashboardView.swift
//  CatIos
//

import SwiftUI

struct DashboardView: View {
    @EnvironmentObject private var petManager: PetManager
    @StateObject private var companionVM = PetCompanionViewModel()

    var onNavigateTab: ((AppTab) -> Void)? = nil
    @State private var showPaywall = false
    @State private var selectedOverviewTab: Int = 0

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                PetSwitcherView()
                    .padding(.horizontal)
                    .padding(.top, 8)
                    .padding(.bottom, 6)

                Picker("View", selection: $selectedOverviewTab) {
                    Text(petManager.isAllPetsSelected ? "🐾 All Pets Overview" : "\(petManager.currentPet.avatarEmoji) \(petManager.currentPet.name)").tag(0)
                    Text("🐾 All Pets (\(petManager.pets.count))").tag(1)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.vertical, 8)
                .onChange(of: petManager.selectedPetId) { _ in
                    if petManager.isAllPetsSelected {
                        selectedOverviewTab = 1
                    } else {
                        selectedOverviewTab = 0
                    }
                }

                ScrollView {
                    VStack(spacing: AppTheme.spacingL) {
                        if selectedOverviewTab == 1 || petManager.isAllPetsSelected {
                            allPetsSummaryHeaderCard
                            allPetsCombinedCareOverviewCard
                            careMetricsGrid
                        } else {
                            petProfileHeaderCard
                            todaysCareOverviewCard
                            aiAssistantShortcutBanner
                            careMetricsGrid
                        }
                    }
                    .padding(.horizontal, AppTheme.spacingM)
                    .padding(.bottom, 30)
                }
            }
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle("Overview")
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
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
        }
    }

    private var allPetsSummaryHeaderCard: some View {
        let pets = petManager.pets
        let avgWellness = pets.isEmpty ? 90 : (pets.reduce(0) { $0 + $1.wellnessScore } / pets.count)

        return VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: AppTheme.spacingM) {
                HStack(spacing: -10) {
                    ForEach(pets) { pet in
                        ZStack {
                            Circle()
                                .fill(Color(hex: pet.petColorHex).opacity(0.2))
                                .frame(width: 44, height: 44)
                            Text(pet.avatarEmoji)
                                .font(.title2)
                        }
                        .overlay(Circle().stroke(Color.white, lineWidth: 2))
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("All My Pets (\(pets.count))")
                            .font(.title3.weight(.bold))
                            .foregroundStyle(AppTheme.textPrimary)
                        Spacer()
                        Text("Family Group")
                            .font(.caption2.weight(.bold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(AppTheme.primary.opacity(0.15))
                            .foregroundColor(AppTheme.primary)
                            .cornerRadius(10)
                    }

                    Text("Tracking \(pets.map { $0.name }.joined(separator: ", "))")
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                }
            }

            Divider()

            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Average Wellness")
                        .font(.caption)
                        .foregroundColor(AppTheme.textSecondary)
                    Text("\(avgWellness)% Health Rating")
                        .font(.subheadline.weight(.bold))
                        .foregroundColor(.green)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Total Reminders Today")
                        .font(.caption)
                        .foregroundColor(AppTheme.textSecondary)
                    Text("6 Care Items Active")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(AppTheme.primary)
                }
            }
        }
        .padding(AppTheme.spacingM)
        .cardStyle()
    }

    private var allPetsCombinedCareOverviewCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacingM) {
            Text("Combined Daily Care Summary")
                .font(.headline)
                .foregroundStyle(AppTheme.textPrimary)

            Divider()

            VStack(spacing: 10) {
                ForEach(petManager.pets) { pet in
                    HStack(spacing: 12) {
                        Text(pet.avatarEmoji)
                            .font(.title2)
                            .padding(8)
                            .background(Color(hex: pet.petColorHex).opacity(0.12))
                            .clipShape(Circle())

                        VStack(alignment: .leading, spacing: 2) {
                            Text(pet.name)
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(AppTheme.textPrimary)
                            Text("\(pet.breed) • Age: \(pet.exactAgeDisplay)")
                                .font(.caption2)
                                .foregroundStyle(AppTheme.textSecondary)
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 2) {
                            Text("\(pet.wellnessScore)% Wellness")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(pet.wellnessScore >= 85 ? .green : .orange)
                            Text("\(pet.todayMoodEmoji) \(pet.todayMoodTitle)")
                                .font(.caption2)
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                    }
                    .padding(10)
                    .background(AppTheme.background.opacity(0.5))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
        .padding(AppTheme.spacingM)
        .cardStyle()
    }

    private var petProfileHeaderCard: some View {
        let pet = petManager.currentPet
        return VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: AppTheme.spacingM) {
                ZStack {
                    Circle()
                        .fill(Color(hex: pet.petColorHex).opacity(0.15))
                        .frame(width: 60, height: 60)
                    Text(pet.avatarEmoji)
                        .font(.system(size: 36))
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(pet.name)
                            .font(.title2.weight(.bold))
                            .foregroundStyle(AppTheme.textPrimary)

                        Spacer()

                        Text(LocalizedStringKey(pet.userRole.rawValue))
                            .font(.caption2.weight(.bold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(AppTheme.primary.opacity(0.15))
                            .foregroundColor(AppTheme.primary)
                            .cornerRadius(10)
                    }

                    Text("\(pet.breed) • \(pet.exactAgeDisplay)")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.textSecondary)
                }
            }

            Divider()

            HStack(spacing: 16) {
                HStack(spacing: 6) {
                    Text("Mood:")
                        .font(.caption)
                        .foregroundColor(AppTheme.textSecondary)
                    Text("\(pet.todayMoodEmoji) \(pet.todayMoodTitle)")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(AppTheme.textPrimary)
                }

                Spacer()

                HStack(spacing: 6) {
                    Text("Wellness:")
                        .font(.caption)
                        .foregroundColor(AppTheme.textSecondary)
                    Text("\(pet.wellnessScore)%")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(pet.wellnessScore >= 85 ? .green : .orange)
                }
            }
        }
        .padding(AppTheme.spacingM)
        .cardStyle()
    }

    private var todaysCareOverviewCard: some View {
        let pet = petManager.currentPet
        return VStack(alignment: .leading, spacing: AppTheme.spacingM) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Today's Care for \(pet.name)")
                        .font(.headline)
                        .foregroundStyle(AppTheme.textPrimary)
                    Text("Daily care summary")
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                }

                Spacer()

                VStack(spacing: 0) {
                    Text("\(pet.wellnessScore)")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.primary)
                    Text("/ 100")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(AppTheme.textSecondary)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(AppTheme.primary.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }

            Divider()

            VStack(spacing: 10) {
                careHighlightRow(icon: "🍗", title: "Food", line1: "✅ Breakfast completed", line2: "Dinner scheduled 7 PM", statusColor: .green)
                careHighlightRow(icon: "💧", title: "Water", line1: "Bowl Refill completed", line2: "Optimal hydration", statusColor: .blue)
                careHighlightRow(icon: pet.petType == .cat ? "🚽" : "🦮", title: pet.petType == .cat ? "Litter Box" : "Walk", line1: pet.petType == .cat ? "2 visits tracked today" : "Morning walk completed", line2: "Normal routine", statusColor: .orange)
            }
        }
        .padding(AppTheme.spacingM)
        .cardStyle()
    }

    private func careHighlightRow(icon: String, title: String, line1: String, line2: String, statusColor: Color) -> some View {
        HStack(spacing: 12) {
            Text(icon)
                .font(.title3)
                .padding(8)
                .background(statusColor.opacity(0.15))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.textPrimary)
                Text(line1)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(AppTheme.textPrimary)
            }

            Spacer()

            Text(line2)
                .font(.caption2)
                .foregroundStyle(AppTheme.textSecondary)
        }
        .padding(10)
        .background(AppTheme.background.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var aiAssistantShortcutBanner: some View {
        let pet = petManager.currentPet
        return HStack(spacing: AppTheme.spacingM) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(colors: [AppTheme.primary, Color.purple], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .frame(width: 44, height: 44)
                Image(systemName: "sparkles")
                    .font(.title3)
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("AI Health & Care Assistant")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(AppTheme.textPrimary)
                Text("Get instant answers about \(pet.name)")
                    .font(.caption2)
                    .foregroundStyle(AppTheme.textSecondary)
            }

            Spacer()

            Button {
                onNavigateTab?(.aiAssistant)
            } label: {
                Text("Ask AI")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(AppTheme.primary)
                    .clipShape(Capsule())
            }
        }
        .padding(AppTheme.spacingM)
        .background(AppTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadiusMedium))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadiusMedium)
                .stroke(AppTheme.primary.opacity(0.3), lineWidth: 1.5)
        )
        .cardShadow()
    }

    private var careMetricsGrid: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacingS) {
            Text("Quick Care Actions")
                .font(.headline)
                .foregroundStyle(AppTheme.textPrimary)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AppTheme.spacingM) {
                DashboardMetricCard(
                    icon: "mouth.fill",
                    emoji: "🍗",
                    title: "Feeding Tracker",
                    subtitle: "Meals & Calories",
                    badge: "Track",
                    color: Color.orange
                ) {
                    onNavigateTab?(.careLog)
                }

                DashboardMetricCard(
                    icon: "drop.fill",
                    emoji: "💧",
                    title: "Water Tracker",
                    subtitle: "Hydration level",
                    badge: "Log",
                    color: Color.blue
                ) {
                    onNavigateTab?(.careLog)
                }

                DashboardMetricCard(
                    icon: petManager.currentPet.petType == .cat ? "square.stack.fill" : "figure.walk",
                    emoji: petManager.currentPet.petType == .cat ? "🚽" : "🦮",
                    title: petManager.currentPet.petType == .cat ? "Litter Box" : "Walk Tracker",
                    subtitle: petManager.currentPet.petType == .cat ? "Bathroom log" : "Exercise log",
                    badge: "History",
                    color: Color.brown
                ) {
                    onNavigateTab?(.careLog)
                }

                DashboardMetricCard(
                    icon: "heart.fill",
                    emoji: "💊",
                    title: "Health & Vet",
                    subtitle: "Vaccines & Meds",
                    badge: "Timeline",
                    color: Color.pink
                ) {
                    onNavigateTab?(.healthMemories)
                }
            }
        }
    }
}

struct DashboardMetricCard: View {
    let icon: String
    let emoji: String
    let title: String
    let subtitle: String
    let badge: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(emoji)
                        .font(.title2)
                    Spacer()
                    Text(badge)
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(color)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(color.opacity(0.12))
                        .clipShape(Capsule())
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppTheme.textPrimary)
                    Text(subtitle)
                        .font(.caption2)
                        .foregroundStyle(AppTheme.textSecondary)
                }
            }
            .padding(AppTheme.spacingM)
            .cardStyle()
        }
        .buttonStyle(.plain)
    }
}
