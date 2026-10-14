//
//  EmptyStateView.swift
//  Patios (CatIos)
//

import SwiftUI

/// Reusable empty / zero-data state with optional action.
struct EmptyStateView: View {
    let systemImage: String
    let title: String
    let message: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: AppTheme.spacingM) {
            ZStack {
                Circle()
                    .fill(AppTheme.primary.opacity(0.12))
                    .frame(width: 72, height: 72)
                Image(systemName: systemImage)
                    .font(.system(size: 32, weight: .semibold))
                    .foregroundStyle(AppTheme.primary)
            }
            .accessibilityHidden(true)

            VStack(spacing: AppTheme.spacingS) {
                Text(title)
                    .font(AppTypography.headline)
                    .foregroundStyle(AppTheme.textPrimary)
                    .multilineTextAlignment(.center)

                Text(message)
                    .font(AppTypography.subheadline)
                    .foregroundStyle(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
            }

            if let actionTitle, let action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(AppTypography.button)
                        .foregroundStyle(.white)
                        .padding(.horizontal, AppTheme.spacingL)
                        .padding(.vertical, 12)
                        .background(AppTheme.primary)
                        .clipShape(Capsule())
                }
                .buttonStyle(PressableButtonStyle())
                .padding(.top, AppTheme.spacingS)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppTheme.spacingXL)
        .padding(.horizontal, AppTheme.spacingM)
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    EmptyStateView(
        systemImage: "heart.text.square",
        title: "No tasks yet",
        message: "Add feeding, meds, or playtime reminders to stay on track.",
        actionTitle: "Add task",
        action: {}
    )
    .background(AppTheme.background)
}
