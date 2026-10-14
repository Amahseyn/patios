//
//  ProBadgeButton.swift
//  Patios (CatIos)
//

import SwiftUI

struct ProBadgeButton: View {
    var action: () -> Void

    var body: some View {
        Button(action: action) {
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
                Capsule().fill(
                    LinearGradient(
                        colors: [AppTheme.secondary, Color.pink.opacity(0.9)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
            )
        }
        .accessibilityLabel("Upgrade to Patios Pro")
    }
}
