//
//  PetScopeChipBar.swift
//  Patios (CatIos)
//
//  Horizontal pet filter chips used on Tasks, Health, and Home.
//

import SwiftUI

struct PetScopeChipBar: View {
    @EnvironmentObject private var petManager: PetManager
    @Binding var selectedPetScopeId: UUID
    var showsAllPetsChip: Bool = true

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                if showsAllPetsChip {
                    scopeChip(
                        label: "All Pets",
                        emoji: "🐾",
                        isSelected: selectedPetScopeId == PetManager.allPetsId,
                        tint: AppTheme.primary
                    ) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                            selectedPetScopeId = PetManager.allPetsId
                        }
                    }
                }

                ForEach(petManager.pets) { pet in
                    scopeChip(
                        label: pet.name,
                        emoji: pet.avatarEmoji,
                        isSelected: selectedPetScopeId == pet.id,
                        tint: Color(hex: pet.petColorHex)
                    ) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                            selectedPetScopeId = pet.id
                        }
                    }
                }
            }
            .padding(.horizontal, AppTheme.spacingM)
            .padding(.vertical, 10)
        }
    }

    private func scopeChip(
        label: String,
        emoji: String,
        isSelected: Bool,
        tint: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(emoji)
                Text(label)
                    .font(.caption.weight(.semibold))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(isSelected ? tint : AppTheme.cardBackground)
            .foregroundStyle(isSelected ? .white : AppTheme.textPrimary)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(isSelected ? Color.clear : AppTheme.textSecondary.opacity(0.15), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(isSelected ? 0.08 : 0.04), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
