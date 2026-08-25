//
//  MyCatsDashboardView.swift
//  CatIos
//

import SwiftUI

struct MyPetsDashboardView: View {
    @EnvironmentObject var petManager: PetManager
    @State private var showAddPetSheet = false

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("All Pet Profiles")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(AppTheme.textPrimary)
                Spacer()

                Button(action: { showAddPetSheet = true }) {
                    Label("Add Pet", systemImage: "plus")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(AppTheme.primary)
                }
            }

            ScrollView {
                VStack(spacing: 12) {
                    ForEach(petManager.pets) { pet in
                        PetOverviewRow(
                            pet: pet,
                            isSelected: pet.id == petManager.selectedPetId,
                            onSelect: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    petManager.selectPet(id: pet.id)
                                }
                            }
                        )
                    }
                }
            }
        }
        .padding(.horizontal)
        .sheet(isPresented: $showAddPetSheet) {
            AddPetModalView()
                .environmentObject(petManager)
        }
    }
}

struct PetOverviewRow: View {
    let pet: PetProfile
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 14) {
                Text(pet.avatarEmoji)
                    .font(.system(size: 32))
                    .frame(width: 50, height: 50)
                    .background(AppTheme.primary.opacity(0.12))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(pet.name)
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(AppTheme.textPrimary)

                        Text(pet.statusSummary)
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(pet.needsAttention ? Color.orange.opacity(0.15) : Color.green.opacity(0.15))
                            .foregroundColor(pet.needsAttention ? .orange : .green)
                            .cornerRadius(8)

                        Spacer()

                        if isSelected {
                            Text("Active")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(AppTheme.primary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(AppTheme.primary.opacity(0.15))
                                .cornerRadius(10)
                        }
                    }

                    HStack(spacing: 12) {
                        Text("Mood: \(pet.todayMoodEmoji) \(pet.todayMoodTitle)")
                            .font(.caption)
                            .foregroundColor(AppTheme.textSecondary)
                        Spacer()
                        Text("Role: \(pet.userRole.rawValue)")
                            .font(.caption2)
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                }
            }
            .padding()
            .background(AppTheme.cardBackground)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? AppTheme.primary : Color.clear, lineWidth: 2)
            )
            .shadow(color: AppTheme.shadowColor, radius: 4, x: 0, y: 2)
        }
    }
}
