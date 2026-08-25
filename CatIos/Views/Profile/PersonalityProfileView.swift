//
//  PersonalityProfileView.swift
//  CatEmotionAI
//

import SwiftUI

struct PersonalityProfileView: View {
    @EnvironmentObject private var petManager: PetManager

    var body: some View {
        let pet = petManager.currentPet
        return ScrollView {
            VStack(spacing: AppTheme.spacingL) {
                VStack(spacing: AppTheme.spacingS) {
                    ZStack {
                        Circle()
                            .fill(AppTheme.primary.opacity(0.15))
                            .frame(width: 80, height: 80)
                        Text(pet.avatarEmoji)
                            .font(.system(size: 48))
                    }

                    Text("\(pet.name)'s Personality")
                        .font(.title.weight(.bold))
                        .foregroundStyle(AppTheme.textPrimary)

                    Text("\(pet.breed) • \(pet.age.displayText)")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.textSecondary)
                }
                .padding(.top, AppTheme.spacingM)

                VStack(alignment: .leading, spacing: AppTheme.spacingM) {
                    Text("Personality Traits")
                        .font(.headline)
                        .foregroundStyle(AppTheme.textPrimary)

                    TraitProgressBar(title: "Playfulness", percentage: pet.playfulness, color: .orange)
                    TraitProgressBar(title: "Social", percentage: pet.social, color: .blue)
                    TraitProgressBar(title: "Vocal", percentage: pet.vocal, color: AppTheme.primary)
                }
                .padding(AppTheme.spacingM)
                .cardStyle()

                VStack(alignment: .leading, spacing: AppTheme.spacingM) {
                    Text("Common Sounds & Behaviors")
                        .font(.headline)
                        .foregroundStyle(AppTheme.textPrimary)

                    VStack(spacing: AppTheme.spacingS) {
                        ForEach(pet.soundPatterns) { pattern in
                            HStack(spacing: AppTheme.spacingM) {
                                ZStack {
                                    Circle()
                                        .fill(AppTheme.primary.opacity(0.1))
                                        .frame(width: 40, height: 40)
                                    Image(systemName: pattern.icon)
                                        .foregroundStyle(AppTheme.primary)
                                }

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(pattern.timeOfDay)
                                        .font(.subheadline.weight(.bold))
                                        .foregroundStyle(AppTheme.textPrimary)
                                    Text("\"\(pattern.description)\"")
                                        .font(.subheadline)
                                        .foregroundStyle(AppTheme.textSecondary)
                                }

                                Spacer()
                            }
                            .padding(AppTheme.spacingS)
                            .background(AppTheme.background)
                            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadiusSmall))
                        }
                    }
                }
                .padding(AppTheme.spacingM)
                .cardStyle()

                MemoryTimelineSection(pet: pet)
            }
            .padding(AppTheme.spacingM)
        }
        .background(AppTheme.background.ignoresSafeArea())
    }
}

struct TraitProgressBar: View {
    let title: String
    let percentage: Int
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.textPrimary)

                Spacer()

                Text("\(percentage)%")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(color)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(color.opacity(0.15))

                    RoundedRectangle(cornerRadius: 6)
                        .fill(color)
                        .frame(width: geo.size.width * CGFloat(percentage) / 100.0)
                }
            }
            .frame(height: 12)
        }
    }
}

struct MemoryTimelineSection: View {
    let pet: PetProfile

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacingM) {
            HStack {
                Label("\(pet.name)'s Memory", systemImage: "clock.arrow.circlepath")
                    .font(.headline)
                    .foregroundStyle(AppTheme.textPrimary)
                Spacer()
                Text("AI Event Log")
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
            }

            VStack(spacing: AppTheme.spacingM) {
                ForEach(pet.memories) { memory in
                    HStack(alignment: .top, spacing: AppTheme.spacingM) {
                        VStack {
                            Text(memory.time)
                                .font(.caption.weight(.bold))
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                        .frame(width: 45)

                        Circle()
                            .fill(AppTheme.primary)
                            .frame(width: 10, height: 10)
                            .padding(.top, 4)

                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("\(memory.emoji) \(memory.title)")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(AppTheme.textPrimary)
                            }
                            Text(memory.category)
                                .font(.caption2)
                                .foregroundStyle(AppTheme.textSecondary)
                        }

                        Spacer()
                    }
                }
            }
        }
        .padding(AppTheme.spacingM)
        .cardStyle()
    }
}

#Preview {
    PersonalityProfileView()
        .environmentObject(PetManager.shared)
}
