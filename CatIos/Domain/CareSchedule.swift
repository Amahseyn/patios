import Foundation

enum CareSchedule {
    static func occurs(_ task: CustomCareTask, on date: Date, calendar: Calendar = .current) -> Bool {
        let day = calendar.startOfDay(for: date)
        let start = calendar.startOfDay(for: task.startDate)
        guard day >= start else { return false }

        switch task.frequency {
        case .daily, .hourly:
            return true
        case .weekly:
            return task.selectedDays.contains(calendar.component(.weekday, from: date))
        case .monthly:
            return calendar.component(.day, from: date) == calendar.component(.day, from: task.startDate)
        case .yearly:
            return calendar.component(.month, from: date) == calendar.component(.month, from: task.startDate)
                && calendar.component(.day, from: date) == calendar.component(.day, from: task.startDate)
        case .custom:
            let interval = max(task.customInterval, 1)
            let count: Int
            switch task.customUnit {
            case .hour:
                count = calendar.dateComponents([.hour], from: task.startDate, to: date).hour ?? 0
            case .day:
                count = calendar.dateComponents([.day], from: start, to: day).day ?? 0
            case .week:
                count = (calendar.dateComponents([.day], from: start, to: day).day ?? 0) / 7
            case .month:
                count = calendar.dateComponents([.month], from: task.startDate, to: date).month ?? 0
            case .year:
                count = calendar.dateComponents([.year], from: task.startDate, to: date).year ?? 0
            }
            return count >= 0 && count % interval == 0
        }
    }

    static func minutes(from timeText: String, calendar: Calendar = .current) -> Int {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = calendar.timeZone
        formatter.dateFormat = "h:mm a"
        if let date = formatter.date(from: timeText) {
            return calendar.component(.hour, from: date) * 60 + calendar.component(.minute, from: date)
        }
        formatter.timeStyle = .short
        formatter.dateFormat = nil
        guard let date = formatter.date(from: timeText) else { return 0 }
        return calendar.component(.hour, from: date) * 60 + calendar.component(.minute, from: date)
    }
}

enum CareAssistantReply {
    static func reply(for prompt: String, petName: String, wellnessScore: Int) -> String {
        let lower = prompt.lowercased()
        let blocked = ["diagnos", "prescri", "disease", "illness", "cancer", "diabetes", "treatment plan", "medication dose"]
        let body: String
        if blocked.contains(where: { lower.contains($0) }) {
            body = "I can’t diagnose, prescribe, name a disease, or suggest a medication dose."
        } else if lower.contains("happy") || lower.contains("mood") {
            body = "\(petName)'s recent care notes look steady. Wellness is around \(wellnessScore)%, which usually means \(petName) is content."
        } else if lower.contains("cry") || lower.contains("night") || lower.contains("bark") {
            body = "Night vocalizing is often hunger, leftover energy, or wanting company. A short play session and a last meal before bed usually helps \(petName)."
        } else if lower.contains("routine") || lower.contains("schedule") {
            body = "Keep \(petName)'s routine predictable: same meal times, an evening play window, and a quiet rest block in the afternoon."
        } else if lower.contains("vaccine") || lower.contains("vet") || lower.contains("health") {
            body = "Use Health for \(petName)'s vaccines and due dates. Turn on the reminder if a booster is coming up."
        } else {
            body = "I can help with \(petName)'s meals, mood, health records, and daily tasks."
        }
        if body.contains(CareInsights.disclaimer) { return body }
        return body + " " + CareInsights.disclaimer
    }
}
