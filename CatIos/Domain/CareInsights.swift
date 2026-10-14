import Foundation

enum MeasureText {
    static func duration(minutes: Int) -> String {
        let minutes = max(0, minutes)
        if minutes < 60 {
            return minutes == 1 ? "1 minute" : "\(minutes) minutes"
        }
        let hours = minutes / 60
        let remainder = minutes % 60
        let hourLabel = hours == 1 ? "1 hour" : "\(hours) hours"
        if remainder == 0 { return hourLabel }
        let minuteLabel = remainder == 1 ? "1 minute" : "\(remainder) minutes"
        return "\(hourLabel) \(minuteLabel)"
    }

    static func calories(_ value: Double) -> String {
        "\(Int(value.rounded())) kcal"
    }

    static func mass(grams: Double) -> String {
        let grams = max(0, grams)
        if grams >= 1000 {
            return "\(_trim(grams / 1000)) kg"
        }
        return "\(_trim(grams)) g"
    }

    private static func _trim(_ value: Double) -> String {
        let text = String(format: "%.2f", value)
        var trimmed = text
        while trimmed.contains(".") && (trimmed.hasSuffix("0") || trimmed.hasSuffix(".")) {
            trimmed.removeLast()
        }
        return trimmed.isEmpty ? "0" : trimmed
    }
}

enum CareInsights {
    static let disclaimer = "This is an informational estimate for care tracking. It is not veterinary advice, a diagnosis, or a feeding prescription."

    struct Portion {
        var dailyCalories: Int
        var caloriesPerMeal: Int
        var gramsPerServing: Int?
        var proteinGrams: Double?
        var fatGrams: Double?
        var fiberGrams: Double?
        var notes: [String]
    }

    static func portion(
        species: String,
        ageYears: Int,
        weightKg: Double,
        activity: String,
        meals: Int,
        caloriesPer100g: Double?,
        proteinPer100g: Double?,
        fatPer100g: Double?,
        fiberPer100g: Double?
    ) -> Portion {
        let resting = 70 * pow(weightKg, 0.75)
        let factor = multiplier(species: species, ageYears: ageYears, activity: activity)
        let daily = max(1, Int((resting * factor).rounded()))
        let perMeal = max(1, Int((Double(daily) / Double(max(meals, 1))).rounded()))
        let grams: Int?
        if let caloriesPer100g, caloriesPer100g > 0 {
            grams = max(1, Int((Double(perMeal) / caloriesPer100g * 100).rounded()))
        } else {
            grams = nil
        }
        var notes = [
            "Estimated energy need is about \(daily) kcal a day for this weight and activity level.",
            "Split across \(meals) meals, that is about \(perMeal) kcal each."
        ]
        if let grams, let caloriesPer100g {
            notes.append("At \(caloriesPer100g.clean) kcal per 100 g, a serving is about \(grams) g.")
        }
        return Portion(
            dailyCalories: daily,
            caloriesPerMeal: perMeal,
            gramsPerServing: grams,
            proteinGrams: macro(proteinPer100g, grams: grams),
            fatGrams: macro(fatPer100g, grams: grams),
            fiberGrams: macro(fiberPer100g, grams: grams),
            notes: notes
        )
    }

    static func calories(grams: Double, per100g: Double?) -> Double? {
        guard let per100g else { return nil }
        return grams * per100g / 100
    }

    private static func multiplier(species: String, ageYears: Int, activity: String) -> Double {
        let name = species.lowercased()
        let young = ageYears < 1
        if name.contains("cat") {
            if young { return 2 }
            return activity == "low" ? 1 : activity == "high" ? 1.4 : 1.2
        }
        if name.contains("dog") {
            if young { return 2 }
            return activity == "low" ? 1.2 : activity == "high" ? 2 : 1.6
        }
        if young { return 1.6 }
        return activity == "low" ? 1.2 : activity == "high" ? 1.8 : 1.4
    }

    private static func macro(_ per100g: Double?, grams: Int?) -> Double? {
        guard let per100g, let grams else { return nil }
        return (per100g * Double(grams) / 100 * 10).rounded() / 10
    }
}

private extension Double {
    var clean: String {
        truncatingRemainder(dividingBy: 1) == 0 ? String(Int(self)) : String(format: "%.1f", self)
    }
}

enum CareAnalytics {
    struct WeightTrend {
        var weeklyDeltaKg: Double?
        var monthlyDeltaKg: Double?
        var direction: String
    }

    struct PeriodReport {
        var calories: Double
        var meals: Int
        var feedingDays: Int
        var foods: [(String, Int)]
        var brands: [(String, Int)]
        var recommendedDaily: Int?
        var behaviors: [(BehaviorKind, Int)]
        var walkCount: Int
        var parkCount: Int
        var trainingCount: Int
        var socialCount: Int
        var activeMinutes: Int
        var weightDeltaKg: Double?
        var latestWeightKg: Double?
        var tasksDone: Int
        var tasksScheduled: Int
        var tasksMissed: Int
        var completionPercent: Int
    }

    static func weightTrend(_ logs: [WeightEntry], now: Date = Date()) -> WeightTrend {
        let weekly = change(logs, acrossDays: 7, now: now)
        let monthly = change(logs, acrossDays: 30, now: now)
        let basis = monthly ?? weekly
        let direction: String
        if let basis {
            if basis > 0.05 { direction = "Gain" }
            else if basis < -0.05 { direction = "Loss" }
            else { direction = "Steady" }
        } else {
            direction = "Not enough logs"
        }
        return WeightTrend(weeklyDeltaKg: weekly, monthlyDeltaKg: monthly, direction: direction)
    }

    static func report(
        days: Int,
        pet: PetProfile?,
        feedings: [FeedingEntry],
        weights: [WeightEntry],
        behaviors: [BehaviorEntry],
        tasks: [CustomCareTask],
        now: Date = Date()
    ) -> PeriodReport {
        let start = now.addingTimeInterval(TimeInterval(-days * 86_400))
        let meals = feedings.filter { $0.fedAt >= start }
        let activity = behaviors.filter { $0.occurredAt >= start }
        let feedingDays = Set(meals.map { Calendar.current.startOfDay(for: $0.fedAt) }).count
        let foods = Dictionary(grouping: meals, by: \.foodName).map { ($0.key, $0.value.count) }.sorted { $0.1 > $1.1 }
        let brands = Dictionary(grouping: meals.filter { !$0.brand.isEmpty }, by: \.brand).map { ($0.key, $0.value.count) }.sorted { $0.1 > $1.1 }
        let counts = Dictionary(grouping: activity, by: \.kind).map { ($0.key, $0.value.count) }.sorted { $0.1 > $1.1 }
        let consistency = taskConsistency(tasks: tasks, days: days)
        let percent = consistency.scheduled == 0 ? 0 : Int((Double(consistency.done) / Double(consistency.scheduled) * 100).rounded())
        let recommended = pet.map { subject in
            let weight = weights.filter { $0.petId == subject.id }.max { $0.loggedAt < $1.loggedAt }?.kilograms ?? weights.last?.kilograms ?? 4
            return CareInsights.portion(
                species: subject.petType.rawValue,
                ageYears: subject.age.years,
                weightKg: weight,
                activity: "moderate",
                meals: 2,
                caloriesPer100g: nil,
                proteinPer100g: nil,
                fatPer100g: nil,
                fiberPer100g: nil
            ).dailyCalories
        }
        return PeriodReport(
            calories: meals.compactMap(\.calories).reduce(0, +),
            meals: meals.count,
            feedingDays: feedingDays,
            foods: foods,
            brands: brands,
            recommendedDaily: recommended,
            behaviors: counts,
            walkCount: activity.filter { $0.kind == .walk }.count,
            parkCount: activity.filter { $0.kind == .park }.count,
            trainingCount: activity.filter { $0.kind == .training }.count,
            socialCount: activity.filter { $0.kind == .social }.count,
            activeMinutes: activity.filter(\.kind.isPositive).reduce(0) { $0 + $1.durationMinutes },
            weightDeltaKg: change(weights, acrossDays: days, now: now),
            latestWeightKg: weights.max { $0.loggedAt < $1.loggedAt }?.kilograms,
            tasksDone: consistency.done,
            tasksScheduled: consistency.scheduled,
            tasksMissed: consistency.missed,
            completionPercent: percent
        )
    }

    struct FoodShare: Identifiable {
        var name: String
        var meals: Int
        var grams: Double
        var calories: Double
        var id: String { name }
    }

    static func foodShares(_ meals: [FeedingEntry]) -> [FoodShare] {
        Dictionary(grouping: meals, by: { $0.foodName.isEmpty ? "Meal" : $0.foodName })
            .map { name, rows in
                FoodShare(
                    name: name,
                    meals: rows.count,
                    grams: rows.reduce(0) { $0 + $1.amountGrams },
                    calories: rows.reduce(0) { $0 + ($1.calories ?? 0) }
                )
            }
            .sorted { lhs, rhs in
                if lhs.meals == rhs.meals { return lhs.name < rhs.name }
                return lhs.meals > rhs.meals
            }
    }

    struct DayPoint: Identifiable {
        var day: Date
        var minutes: Int
        var sessions: Int
        var id: Date { day }
    }

    struct ActivityFocus {
        var sessions: Int
        var minutes: Int
        var averageMinutes: Int
        var activeDays: Int
        var longestMinutes: Int
        var streak: Int
        var moods: [(String, Int)]
        var places: [(String, Int)]
        var days: [DayPoint]
        var counts: [(BehaviorKind, Int)]
        var notes: [String]
    }

    static func activityFocus(
        entries: [BehaviorEntry],
        kind: BehaviorKind?,
        days windowDays: Int,
        petName: String,
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> ActivityFocus {
        let start = now.addingTimeInterval(TimeInterval(-windowDays * 86_400))
        let matching = entries.filter { entry in
            entry.occurredAt >= start && entry.occurredAt <= now && (kind == nil || entry.kind == kind)
        }
        let minutes = matching.reduce(0) { $0 + $1.durationMinutes }
        let sessions = matching.count
        let activeDays = Set(matching.map { calendar.startOfDay(for: $0.occurredAt) }).count
        let longest = matching.map(\.durationMinutes).max() ?? 0
        let average = sessions == 0 ? 0 : Int((Double(minutes) / Double(sessions)).rounded())
        let streak = kind.map { kindStreak(entries, kind: $0, now: now, calendar: calendar) } ?? positiveStreak(entries, calendar: calendar)
        let counts = Dictionary(grouping: matching, by: \.kind)
            .map { ($0.key, $0.value.count) }
            .sorted { lhs, rhs in
                if lhs.1 == rhs.1 { return lhs.0.rawValue < rhs.0.rawValue }
                return lhs.1 > rhs.1
            }
        return ActivityFocus(
            sessions: sessions,
            minutes: minutes,
            averageMinutes: average,
            activeDays: activeDays,
            longestMinutes: longest,
            streak: streak,
            moods: rankedLabels(matching.map(\.mood)),
            places: rankedLabels(matching.map(\.location)),
            days: dayPoints(matching, from: start, through: now, calendar: calendar),
            counts: counts,
            notes: activityNotes(
                kind: kind,
                petName: petName,
                windowDays: windowDays,
                sessions: sessions,
                minutes: minutes,
                average: average,
                longest: longest,
                activeDays: activeDays,
                streak: streak,
                counts: counts,
                moods: rankedLabels(matching.map(\.mood)),
                places: rankedLabels(matching.map(\.location)),
                severity: averageSeverity(matching, kind: kind)
            )
        )
    }

    static func kindStreak(_ entries: [BehaviorEntry], kind: BehaviorKind, now: Date = Date(), calendar: Calendar = .current) -> Int {
        let days = Set(entries.filter { $0.kind == kind }.map { calendar.startOfDay(for: $0.occurredAt) })
        return dayStreak(days, now: now, calendar: calendar)
    }

    static func behaviorCounts(_ entries: [BehaviorEntry], within days: Int, now: Date = Date()) -> [(BehaviorKind, Int)] {
        let start = now.addingTimeInterval(TimeInterval(-days * 86_400))
        let filtered = entries.filter { $0.occurredAt >= start }
        let grouped = Dictionary(grouping: filtered, by: \.kind)
        return grouped.map { ($0.key, $0.value.count) }.sorted { $0.1 > $1.1 }
    }

    static func positiveStreak(_ entries: [BehaviorEntry], calendar: Calendar = .current) -> Int {
        let days = Set(entries.filter(\.kind.isPositive).map { calendar.startOfDay(for: $0.occurredAt) })
        var cursor = calendar.startOfDay(for: Date())
        if !days.contains(cursor) {
            cursor = calendar.date(byAdding: .day, value: -1, to: cursor) ?? cursor
        }
        var streak = 0
        while days.contains(cursor) {
            streak += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = previous
        }
        return streak
    }

    static func taskConsistency(tasks: [CustomCareTask], days: Int, calendar: Calendar = .current) -> (done: Int, scheduled: Int, missed: Int) {
        let today = calendar.startOfDay(for: Date())
        var scheduled = 0
        var done = 0
        for offset in 1...days {
            guard let day = calendar.date(byAdding: .day, value: -offset, to: today) else { continue }
            for task in tasks where CareSchedule.occurs(task, on: day, calendar: calendar) {
                scheduled += 1
                if completed(task, on: day, calendar: calendar) {
                    done += 1
                }
            }
        }
        return (done, scheduled, max(0, scheduled - done))
    }

    static func currentStreak(tasks: [CustomCareTask], calendar: Calendar = .current) -> Int {
        let today = calendar.startOfDay(for: Date())
        var cursor = calendar.date(byAdding: .day, value: -1, to: today) ?? today
        var streak = 0
        while true {
            let due = tasks.filter { CareSchedule.occurs($0, on: cursor, calendar: calendar) }
            if due.isEmpty { break }
            if due.contains(where: { !completed($0, on: cursor, calendar: calendar) }) { break }
            streak += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = previous
            if streak > 60 { break }
        }
        return streak
    }

    private static func dayStreak(_ days: Set<Date>, now: Date, calendar: Calendar) -> Int {
        var cursor = calendar.startOfDay(for: now)
        if !days.contains(cursor) {
            cursor = calendar.date(byAdding: .day, value: -1, to: cursor) ?? cursor
        }
        var streak = 0
        while days.contains(cursor) {
            streak += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = previous
        }
        return streak
    }

    private static func dayPoints(_ entries: [BehaviorEntry], from start: Date, through now: Date, calendar: Calendar) -> [DayPoint] {
        var buckets: [Date: (minutes: Int, sessions: Int)] = [:]
        for entry in entries {
            let day = calendar.startOfDay(for: entry.occurredAt)
            let current = buckets[day] ?? (0, 0)
            buckets[day] = (current.minutes + entry.durationMinutes, current.sessions + 1)
        }
        var cursor = calendar.startOfDay(for: start)
        let end = calendar.startOfDay(for: now)
        var points: [DayPoint] = []
        while cursor <= end {
            let value = buckets[cursor] ?? (0, 0)
            points.append(DayPoint(day: cursor, minutes: value.minutes, sessions: value.sessions))
            guard let next = calendar.date(byAdding: .day, value: 1, to: cursor) else { break }
            cursor = next
        }
        return points
    }

    private static func rankedLabels(_ values: [String]) -> [(String, Int)] {
        Dictionary(grouping: values.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }, by: { $0 })
            .map { ($0.key, $0.value.count) }
            .sorted { lhs, rhs in
                if lhs.1 == rhs.1 { return lhs.0 < rhs.0 }
                return lhs.1 > rhs.1
            }
    }

    private static func averageSeverity(_ entries: [BehaviorEntry], kind: BehaviorKind?) -> Double? {
        guard let kind, !kind.isPositive, !entries.isEmpty else { return nil }
        let total = entries.reduce(0) { $0 + $1.severity }
        return Double(total) / Double(entries.count)
    }

    private static func activityNotes(
        kind: BehaviorKind?,
        petName: String,
        windowDays: Int,
        sessions: Int,
        minutes: Int,
        average: Int,
        longest: Int,
        activeDays: Int,
        streak: Int,
        counts: [(BehaviorKind, Int)],
        moods: [(String, Int)],
        places: [(String, Int)],
        severity: Double?
    ) -> [String] {
        let windowName = windowDays > 7 ? "month" : "week"
        if let kind {
            if sessions == 0 {
                return ["No \(kind.rawValue.lowercased()) notes for \(petName) in this \(windowName)."]
            }
            var notes = [
                "\(petName) logged \(kind.rawValue.lowercased()) \(spell(sessions, singular: "time")), \(MeasureText.duration(minutes: minutes)) in all.",
                "A typical session was about \(MeasureText.duration(minutes: average)), and the longest was \(MeasureText.duration(minutes: longest)).",
                "Those notes cover \(spell(activeDays, singular: "day"))\(streak > 0 ? ", with a current streak of \(spell(streak, singular: "day"))" : "")."
            ]
            if let mood = moods.first {
                notes.append("The usual mood was \(mood.0).")
            }
            if let place = places.first {
                notes.append("The usual place was \(place.0).")
            }
            if let severity {
                notes.append(String(format: "Average intensity was %.1f out of 5.", severity))
            }
            return notes
        }
        if sessions == 0 {
            return ["No activities are logged for \(petName) in this \(windowName)."]
        }
        let leading = counts.prefix(3).map { "\($0.0.rawValue) \($0.1)" }.joined(separator: ", ")
        var notes = [
            "\(petName) logged \(spell(sessions, singular: "activity", plural: "activities")), \(MeasureText.duration(minutes: minutes)) of activity this \(windowName).",
            "Most often: \(leading)."
        ]
        if streak > 0 {
            notes.append("Positive activities are on a \(spell(streak, singular: "day")) streak.")
        }
        return notes
    }

    private static func spell(_ count: Int, singular: String, plural: String? = nil) -> String {
        count == 1 ? "1 \(singular)" : "\(count) \(plural ?? "\(singular)s")"
    }

    private static func completed(_ task: CustomCareTask, on day: Date, calendar: Calendar) -> Bool {
        let dayStart = calendar.startOfDay(for: day)
        if task.occurrenceLog.contains(where: { $0.status == "completed" && calendar.isDate($0.occurredAt, inSameDayAs: dayStart) }) {
            return true
        }
        guard let offset = task.completedDateOffset else { return false }
        let today = calendar.startOfDay(for: Date())
        let completedDay = calendar.date(byAdding: .day, value: offset, to: today) ?? today
        return calendar.isDate(completedDay, inSameDayAs: dayStart)
    }

    static func change(_ logs: [WeightEntry], acrossDays days: Int, now: Date = Date(), calendar: Calendar = .current) -> Double? {
        let sorted = logs.sorted { $0.loggedAt < $1.loggedAt }
        guard let latest = sorted.last else { return nil }
        let boundary = calendar.date(byAdding: .day, value: -days, to: now) ?? now
        let earlier = sorted.last { $0.loggedAt <= boundary && $0.id != latest.id } ?? sorted.first { $0.id != latest.id }
        guard let earlier else { return nil }
        return latest.kilograms - earlier.kilograms
    }
}
