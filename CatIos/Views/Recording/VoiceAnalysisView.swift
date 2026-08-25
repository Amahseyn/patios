//
//  VoiceAnalysisView.swift
//  CatIos
//

import SwiftUI

enum AnalysisState {
    case ready
    case recording
    case processing
    case result
}

struct VoiceAnalysisView: View {
    @EnvironmentObject private var petManager: PetManager
    @State private var currentState: AnalysisState = .ready
    @State private var recordingTimerSeconds: Int = 0
    @State private var timer: Timer? = nil

    var body: some View {
        NavigationStack {
            VStack {
                switch currentState {
                case .ready:
                    readyScreen
                case .recording:
                    recordingScreen
                case .processing:
                    processingScreen
                case .result:
                    resultScreen
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle("Voice Analysis")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var readyScreen: some View {
        VStack(spacing: AppTheme.spacingXL) {
            Spacer()

            VStack(spacing: AppTheme.spacingS) {
                Text("AI Vocal Scanner")
                    .font(.largeTitle.weight(.bold))
                    .foregroundStyle(AppTheme.textPrimary)

                Text("Record \(petManager.currentPet.name)'s sound to decode emotion and mood.")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AppTheme.spacingL)
            }

            Spacer()

            Button {
                startRecording()
            } label: {
                VStack(spacing: AppTheme.spacingM) {
                    ZStack {
                        Circle()
                            .fill(AppTheme.primary.opacity(0.15))
                            .frame(width: 170, height: 170)

                        Circle()
                            .fill(AppTheme.primary)
                            .frame(width: 120, height: 120)
                            .shadow(color: AppTheme.primary.opacity(0.5), radius: 20, x: 0, y: 10)

                        Image(systemName: "mic.fill")
                            .font(.system(size: 48, weight: .semibold))
                            .foregroundStyle(.white)
                    }

                    Text("Record \(petManager.currentPet.name)'s Sound")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(AppTheme.primary)
                }
            }
            .buttonStyle(.plain)

            Spacer()
        }
        .padding(AppTheme.spacingL)
    }

    private var recordingScreen: some View {
        VStack(spacing: AppTheme.spacingXL) {
            Spacer()

            Text("Listening to \(petManager.currentPet.name)...")
                .font(.title2.weight(.bold))
                .foregroundStyle(AppTheme.textPrimary)

            HStack(spacing: 6) {
                ForEach(0..<12, id: \.self) { index in
                    WaveformBar(index: index)
                }
            }
            .frame(height: 80)

            Text(timeString(from: recordingTimerSeconds))
                .font(.system(size: 44, weight: .bold, design: .monospaced))
                .foregroundStyle(AppTheme.primary)

            Spacer()

            Button {
                stopRecordingAndProcess()
            } label: {
                Text("Stop & Analyze")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(AppTheme.primary)
                    .clipShape(Capsule())
            }
            .padding(.horizontal, AppTheme.spacingL)
            .padding(.bottom, AppTheme.spacingL)
        }
    }

    private var processingScreen: some View {
        VStack(spacing: AppTheme.spacingL) {
            Spacer()

            ProgressView()
                .scaleEffect(2.0)
                .tint(AppTheme.primary)
                .padding(.bottom, AppTheme.spacingM)

            Text("AI is understanding your pet...")
                .font(.title3.weight(.bold))
                .foregroundStyle(AppTheme.textPrimary)

            Text("Analyzing acoustic frequencies and pitch patterns...")
                .font(.subheadline)
                .foregroundStyle(AppTheme.textSecondary)

            Spacer()
        }
    }

    private var resultScreen: some View {
        ScrollView {
            VStack(spacing: AppTheme.spacingL) {
                VStack(spacing: AppTheme.spacingS) {
                    Text("😊")
                        .font(.system(size: 72))

                    Text("Happy")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.textPrimary)

                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.shield.fill")
                            .foregroundStyle(AppTheme.success)
                        Text("92% Confidence")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(AppTheme.success)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(AppTheme.success.opacity(0.12))
                    .clipShape(Capsule())
                }
                .padding(.top, AppTheme.spacingM)

                VStack(alignment: .leading, spacing: AppTheme.spacingS) {
                    Label("AI Explanation", systemImage: "sparkles")
                        .font(.headline)
                        .foregroundStyle(AppTheme.primary)

                    Text("\"\(petManager.currentPet.name) sounds relaxed and comfortable. This type of sound usually happens during positive interactions.\"")
                        .font(.body)
                        .foregroundStyle(AppTheme.textPrimary)
                        .lineSpacing(4)
                }
                .padding(AppTheme.spacingM)
                .cardStyle()

                VStack(alignment: .leading, spacing: AppTheme.spacingM) {
                    Text("Suggested Actions")
                        .font(.headline)
                        .foregroundStyle(AppTheme.textPrimary)

                    ActionRowItem(text: "Continue play time")
                    ActionRowItem(text: "Maintain current routine")
                    ActionRowItem(text: "Offer a small reward or treat")
                }
                .padding(AppTheme.spacingM)
                .cardStyle()

                VStack(spacing: AppTheme.spacingM) {
                    Button {
                        let formatter = DateFormatter()
                        formatter.dateFormat = "HH:mm"
                        petManager.addMemoryToCurrentPet(
                            time: formatter.string(from: Date()),
                            title: "Happy vocalization detected (92%)",
                            emoji: "😊",
                            category: "Voice AI"
                        )
                        currentState = .ready
                    } label: {
                        Text("Save to Memory Timeline")
                            .font(.headline.weight(.bold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(AppTheme.primary)
                            .clipShape(Capsule())
                    }

                    Button {
                        currentState = .ready
                    } label: {
                        Text("Record Another Sound")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                }
                .padding(.bottom, AppTheme.spacingL)
            }
            .padding(AppTheme.spacingM)
        }
    }

    private func startRecording() {
        currentState = .recording
        recordingTimerSeconds = 0
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            recordingTimerSeconds += 1
            if recordingTimerSeconds >= 4 {
                stopRecordingAndProcess()
            }
        }
    }

    private func stopRecordingAndProcess() {
        timer?.invalidate()
        timer = nil
        currentState = .processing

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            currentState = .result
        }
    }

    private func timeString(from seconds: Int) -> String {
        let mins = seconds / 60
        let secs = seconds % 60
        return String(format: "%02d:%02d", mins, secs)
    }
}

struct WaveformBar: View {
    let index: Int
    @State private var heightMultiplier: CGFloat = 0.3

    var body: some View {
        RoundedRectangle(cornerRadius: 3)
            .fill(AppTheme.primary)
            .frame(width: 6, height: 60 * heightMultiplier)
            .onAppear {
                withAnimation(
                    .easeInOut(duration: 0.4)
                    .repeatForever(autoreverses: true)
                    .delay(Double(index) * 0.08)
                ) {
                    heightMultiplier = CGFloat.random(in: 0.3...1.0)
                }
            }
    }
}

struct ActionRowItem: View {
    let text: String

    var body: some View {
        HStack(spacing: AppTheme.spacingS) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(AppTheme.success)
                .font(.headline)
            Text(text)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(AppTheme.textPrimary)
            Spacer()
        }
    }
}

#Preview {
    NavigationStack {
        VoiceAnalysisView()
    }
    .environmentObject(PetManager.shared)
}
