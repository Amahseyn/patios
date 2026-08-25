//
//  WaveformView.swift
//  CatEmotionAI
//
//  Purely decorative animated waveform used while "recording" is mocked.
//  Bars animate to randomized heights to simulate live audio input.
//

import SwiftUI

struct WaveformView: View {
    var isAnimating: Bool
    var barCount: Int = 28
    var tint: Color = AppTheme.primary

    @State private var heights: [CGFloat] = []

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<barCount, id: \.self) { index in
                RoundedRectangle(cornerRadius: 2)
                    .fill(tint.opacity(0.85))
                    .frame(width: 4, height: heights.indices.contains(index) ? heights[index] : 6)
            }
        }
        .frame(height: 60)
        .onAppear {
            heights = (0..<barCount).map { _ in CGFloat.random(in: 6...20) }
            if isAnimating {
                animate()
            }
        }
        .onChange(of: isAnimating) { _, newValue in
            if newValue { animate() }
        }
    }

    private func animate() {
        guard isAnimating else { return }
        withAnimation(.easeInOut(duration: 0.35)) {
            heights = (0..<barCount).map { _ in CGFloat.random(in: 6...56) }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            if isAnimating { animate() }
        }
    }
}

#Preview {
    WaveformView(isAnimating: true)
        .padding()
}
