//
//  RecordingView.swift
//  CatEmotionAI
//
//  Recording UI mockup. Cycles through Ready -> Recording -> Processing ->
//  Completed using RecordingViewModel's simulated timers. No real audio
//  capture is implemented — this is UI/UX only.
//

import SwiftUI

struct RecordingView: View {
    @StateObject private var viewModel = RecordingViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var navigateToResult = false

    var body: some View {
        VStack(spacing: AppTheme.spacingXL) {
            Spacer()

            statusLabel

            micCircle

            Text(viewModel.timerText)
                .font(.system(size: 44, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.textPrimary)
                .monospacedDigit()
                .opacity(viewModel.state == .ready ? 0.3 : 1.0)

            WaveformView(isAnimating: viewModel.state == .recording)
                .opacity(viewModel.state == .recording ? 1.0 : 0.25)

            Spacer()

            actionButton
                .padding(.horizontal, AppTheme.spacingL)
                .padding(.bottom, AppTheme.spacingL)
        }
        .background(AppTheme.background.ignoresSafeArea())
        .navigationTitle("Recording")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $navigateToResult) {
            if let result = viewModel.mockResult {
                AnalysisResultView(result: result)
            }
        }
        .onChange(of: viewModel.state) { _, newState in
            if newState == .completed {
                navigateToResult = true
            }
        }
    }

    private var statusLabel: some View {
        Text(statusText)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(AppTheme.textSecondary)
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
            .background(AppTheme.primary.opacity(0.1))
            .clipShape(Capsule())
    }

    private var statusText: String {
        switch viewModel.state {
        case .ready: return "Ready"
        case .recording: return "Recording…"
        case .processing: return "Processing…"
        case .completed: return "Completed"
        }
    }

    private var micCircle: some View {
        ZStack {
            Circle()
                .fill(AppTheme.primary.opacity(0.12))
                .frame(width: 220, height: 220)
                .scaleEffect(viewModel.state == .recording ? 1.1 : 1.0)
                .animation(
                    viewModel.state == .recording
                        ? .easeInOut(duration: 1.0).repeatForever(autoreverses: true)
                        : .default,
                    value: viewModel.state
                )

            Circle()
                .fill(AppTheme.micGradient)
                .frame(width: 160, height: 160)
                .shadow(color: AppTheme.primary.opacity(0.4), radius: 24, y: 12)

            Group {
                switch viewModel.state {
                case .processing:
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(.white)
                        .scaleEffect(1.6)
                case .completed:
                    Image(systemName: "checkmark")
                        .font(.system(size: 56, weight: .bold))
                        .foregroundStyle(.white)
                default:
                    Image(systemName: "mic.fill")
                        .font(.system(size: 56, weight: .semibold))
                        .foregroundStyle(.white)
                }
            }
        }
    }

    @ViewBuilder
    private var actionButton: some View {
        switch viewModel.state {
        case .ready:
            PrimaryButton(title: "Start Recording", systemImage: "mic.fill") {
                viewModel.startRecording()
            }
        case .recording:
            PrimaryButton(title: "Stop", systemImage: "stop.fill") {
                viewModel.stopRecording()
            }
        case .processing:
            SecondaryButton(title: "Analyzing…", systemImage: "sparkles") {}
                .disabled(true)
        case .completed:
            SecondaryButton(title: "Record Again", systemImage: "arrow.clockwise") {
                viewModel.reset()
            }
        }
    }
}

#Preview {
    NavigationStack {
        RecordingView()
    }
}
