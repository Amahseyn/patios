//
//  CatProfileCard.swift
//  CatEmotionAI
//
//  Small top-of-dashboard card showing the active pet's avatar and name.
//

import SwiftUI

struct PetProfileCard: View {
    let profile: PetProfile

    var body: some View {
        HStack(spacing: AppTheme.spacingM) {
            ZStack {
                Circle()
                    .fill(AppTheme.heroGradient)
                Image(systemName: profile.petType.systemIcon)
                    .font(.system(size: 26))
                    .foregroundStyle(.white)
            }
            .frame(width: 56, height: 56)

            VStack(alignment: .leading, spacing: 2) {
                Text("Welcome back 👋")
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
                Text(profile.name)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(AppTheme.textPrimary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundStyle(AppTheme.textSecondary)
                .font(.subheadline.weight(.semibold))
        }
        .padding(AppTheme.spacingM)
        .cardStyle()
    }
}

#Preview {
    PetProfileCard(profile: .mockLuna)
        .padding()
}
