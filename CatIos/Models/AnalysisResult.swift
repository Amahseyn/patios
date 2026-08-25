//
//  AnalysisResult.swift
//  CatIos
//
//  Represents a single completed (mock) analysis of a pet sound recording.
//

import Foundation

struct AnalysisResult: Identifiable, Codable {
    let id: UUID
    let emotion: PetEmotion
    let confidence: Double        // 0.0 ... 1.0
    let date: Date
    let durationSeconds: Int

    init(
        id: UUID = UUID(),
        emotion: PetEmotion,
        confidence: Double,
        date: Date,
        durationSeconds: Int
    ) {
        self.id = id
        self.emotion = emotion
        self.confidence = confidence
        self.date = date
        self.durationSeconds = durationSeconds
    }

    var confidencePercentText: String {
        "\(Int(confidence * 100))%"
    }

    var durationText: String {
        let minutes = durationSeconds / 60
        let seconds = durationSeconds % 60
        return minutes > 0 ? "\(minutes)m \(seconds)s" : "\(seconds)s"
    }

    var relativeDateText: String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "Today, \(Self.timeFormatter.string(from: date))"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            return Self.dateFormatter.string(from: date)
        }
    }

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter
    }()

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter
    }()
}

// MARK: - Mock Data
enum MockData {
    static let recentAnalyses: [AnalysisResult] = [
        AnalysisResult(
            emotion: .happy,
            confidence: 0.92,
            date: Calendar.current.date(bySettingHour: 10, minute: 30, second: 0, of: Date()) ?? Date(),
            durationSeconds: 8
        ),
        AnalysisResult(
            emotion: .hungry,
            confidence: 0.86,
            date: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date(),
            durationSeconds: 5
        ),
        AnalysisResult(
            emotion: .curious,
            confidence: 0.78,
            date: Calendar.current.date(byAdding: .day, value: -2, to: Date()) ?? Date(),
            durationSeconds: 12
        ),
        AnalysisResult(
            emotion: .anxious,
            confidence: 0.71,
            date: Calendar.current.date(byAdding: .day, value: -4, to: Date()) ?? Date(),
            durationSeconds: 6
        ),
        AnalysisResult(
            emotion: .playful,
            confidence: 0.88,
            date: Calendar.current.date(byAdding: .day, value: -6, to: Date()) ?? Date(),
            durationSeconds: 15
        )
    ]

    static let sampleResult = recentAnalyses[0]
}
