//
//  RecordingViewModel.swift
//  CatEmotionAI
//
//  Drives the mock recording state machine. No real audio capture —
//  timers simulate the passage of time so the UI can be fully previewed.
//

import SwiftUI
import Combine

enum RecordingState {
    case ready
    case recording
    case processing
    case completed
}

@MainActor
final class RecordingViewModel: ObservableObject {
    @Published var state: RecordingState = .ready
    @Published var elapsedSeconds: Int = 0
    @Published var mockResult: AnalysisResult?

    private var timerCancellable: AnyCancellable?

    func startRecording() {
        guard state == .ready else { return }
        state = .recording
        elapsedSeconds = 0
        timerCancellable = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.elapsedSeconds += 1
            }
    }

    func stopRecording() {
        guard state == .recording else { return }
        timerCancellable?.cancel()
        state = .processing

        Task {
            try? await Task.sleep(nanoseconds: 1_800_000_000)
            await MainActor.run {
                self.mockResult = AnalysisResult(
                    emotion: .happy,
                    confidence: 0.92,
                    date: Date(),
                    durationSeconds: self.elapsedSeconds
                )
                self.state = .completed
            }
        }
    }

    func reset() {
        timerCancellable?.cancel()
        elapsedSeconds = 0
        mockResult = nil
        state = .ready
    }

    var timerText: String {
        let minutes = elapsedSeconds / 60
        let seconds = elapsedSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
