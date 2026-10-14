//
//  SectionHeader.swift
//  Patios (CatIos)
//

import SwiftUI

struct SectionHeader: View {
    let title: String
    var subtitle: String? = nil
    var trailingTitle: String? = nil
    var trailingAction: (() -> Void)? = nil

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AppTypography.headline)
                    .foregroundStyle(AppTheme.textPrimary)
                if let subtitle {
                    Text(subtitle)
                        .font(AppTypography.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                }
            }
            Spacer()
            if let trailingTitle, let trailingAction {
                Button(trailingTitle, action: trailingAction)
                    .font(AppTypography.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.primary)
            }
        }
    }
}
