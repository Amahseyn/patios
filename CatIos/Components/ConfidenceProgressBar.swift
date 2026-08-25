//
//  ConfidenceProgressBar.swift
//  CatEmotionAI
//
//  Animated horizontal progress bar showing the AI's mock confidence score.
//

import SwiftUI

struct ConfidenceProgressBar: View {
    let progress: Double   // 0.0 ... 1.0
    var tint: Color = AppTheme.primary

    @State private var animatedProgress: Double = 0

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(tint.opacity(0.15))

                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [tint.opacity(0.7), tint],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geometry.size.width * animatedProgress)
            }
        }
        .frame(height: 10)
        .onAppear {
            withAnimation(.easeOut(duration: 0.9).delay(0.1)) {
                animatedProgress = progress
            }
        }
        .onChange(of: progress) { _, newValue in
            withAnimation(.easeOut(duration: 0.6)) {
                animatedProgress = newValue
            }
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        ConfidenceProgressBar(progress: 0.92, tint: AppTheme.success)
        ConfidenceProgressBar(progress: 0.55, tint: AppTheme.warning)
    }
    .padding()
}
