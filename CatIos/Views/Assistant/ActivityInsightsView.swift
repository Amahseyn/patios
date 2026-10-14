import Charts
import SwiftUI

struct ActivityInsightsView: View {
    @EnvironmentObject private var pets: PetManager
    @EnvironmentObject private var wellness: WellnessStore
    @EnvironmentObject private var tasks: CareTaskStore
    @EnvironmentObject private var auth: AuthSession

    @State private var petId = PetManager.shared.currentPet.id
    @State private var period = 7
    @State private var topic: InsightTopic = .activities
    @State private var activity: BehaviorKind?
    @State private var remoteNotes: [String]?
    @State private var summaryNotes: [String] = []
    @State private var narrativeSource: String?
    @State private var loadingNarrative = false

    var body: some View {
        List {
            Section {
                FantasyHeroHeader(
                    title: "Insights",
                    subtitle: auth.isSignedIn
                        ? "Patterns from your logs over this \(periodName)."
                        : "Charts from this iPhone. Sign in from You for account-based highlights.",
                    systemImage: "chart.xyaxis.line"
                )
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            }

            filters
            narrative
            insightBody
            Section {
                InsightDisclaimer()
            }
        }
        .scrollContentBackground(.hidden)
        .task(id: requestKey) {
            await loadNarrative()
        }
    }

    private var filters: some View {
        Section {
            PetScopePicker(selection: $petId, pets: pets.pets)
            Picker("Period", selection: $period) {
                Text("Week").tag(7)
                Text("Month").tag(30)
            }
            .pickerStyle(.segmented)
            topicFilters
            if topic == .activities {
                activityFilters
                filterChart
            }
        } footer: {
            Text(topic.footer)
        }
    }

    private var topicFilters: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppTheme.spacingS) {
                ForEach(InsightTopic.allCases) { item in
                    let selected = topic == item
                    Button {
                        topic = item
                        if item != .activities {
                            activity = nil
                        }
                    } label: {
                        FantasyTopicChip(title: item.rawValue, systemImage: item.symbol)
                            .opacity(selected ? 1 : 0.72)
                            .overlay {
                                if selected {
                                    Capsule(style: .continuous)
                                        .strokeBorder(item.tint.opacity(0.6), lineWidth: 1.5)
                                }
                            }
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(selected ? .isSelected : [])
                }
            }
            .padding(.vertical, 4)
        }
        .accessibilityLabel("Insight")
    }

    private var activityFilters: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppTheme.spacingS) {
                filterChip(title: "All", systemImage: "square.grid.2x2", kind: nil, count: allSessions)
                ForEach(BehaviorKind.allCases) { kind in
                    filterChip(
                        title: kind.rawValue,
                        systemImage: kind.symbol,
                        kind: kind,
                        count: sessionCount(kind)
                    )
                }
            }
            .padding(.vertical, 4)
        }
        .accessibilityLabel("Activity")
    }

    private func filterChip(title: String, systemImage: String, kind: BehaviorKind?, count: Int) -> some View {
        let selected = activity == kind
        let label = count > 0 ? "\(title) \(count)" : title
        return Button {
            activity = kind
        } label: {
            Label(label, systemImage: systemImage)
                .font(.caption.weight(.semibold))
        }
        .buttonStyle(.bordered)
        .tint(selected ? AppTheme.analytics : AppTheme.textSecondary)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    private var narrative: some View {
        Section {
            if loadingNarrative {
                ProgressView("Reading this activity")
            }
            ForEach(shownNotes, id: \.self) { note in
                Text(note)
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textPrimary)
            }
            if let narrativeSource {
                Text(narrativeSource)
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
            }
            if !summaryNotes.isEmpty {
                ForEach(summaryNotes, id: \.self) { note in
                    Text(note)
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.textPrimary)
                }
            }
            Text(CareInsights.disclaimer)
                .font(.caption)
                .foregroundStyle(AppTheme.textSecondary)
        } header: {
            Text(sectionTitle)
        }
    }

    @ViewBuilder
    private var insightBody: some View {
        switch topic {
        case .activities:
            if let activity {
                activityDetail(activity)
            } else {
                overview
            }
        case .completed:
            completedDetail
        case .calories:
            calorieDetail
        case .foods:
            foodDetail
        }
    }

    @ViewBuilder
    private func activityDetail(_ kind: BehaviorKind) -> some View {
        if focus.sessions == 0 {
            Section {
                EmptyStateView(
                    systemImage: kind.symbol,
                    title: "No \(kind.rawValue.lowercased()) yet",
                    message: "Log \(kind.rawValue.lowercased()) in Health, then come back for minutes, places, and a streak."
                )
            }
        } else {
            Section("This \(periodName)") {
                metric("Sessions", "\(focus.sessions)")
                metric("Time", MeasureText.duration(minutes: focus.minutes))
                metric("Typical length", MeasureText.duration(minutes: focus.averageMinutes))
                metric("Longest", MeasureText.duration(minutes: focus.longestMinutes))
                metric("Days", "\(focus.activeDays)")
                metric("Streak", "\(focus.streak) days")
            }
            if !focus.moods.isEmpty {
                Section("Mood") {
                    ForEach(focus.moods.prefix(4), id: \.0) { mood, count in
                        metric(mood, "\(count)")
                    }
                }
            }
            if !focus.places.isEmpty {
                Section("Places") {
                    ForEach(focus.places.prefix(4), id: \.0) { place, count in
                        metric(place, "\(count)")
                    }
                }
            }
            Section("Recent") {
                ForEach(recentEntries) { entry in
                    VStack(alignment: .leading, spacing: 2) {
                        Label(entry.title.isEmpty ? entry.kind.rawValue : entry.title, systemImage: entry.icon)
                        Text(entryLine(entry))
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                    .accessibilityElement(children: .combine)
                }
            }
        }
    }

    @ViewBuilder
    private var overview: some View {
        if focus.sessions > 0 {
            Section("Activities") {
                ForEach(focus.counts, id: \.0) { kind, count in
                    Button {
                        activity = kind
                    } label: {
                        metric(kind.rawValue, "\(count)")
                    }
                    .foregroundStyle(AppTheme.textPrimary)
                }
            }
        } else {
            Section {
                EmptyStateView(
                    systemImage: "figure.walk",
                    title: "No activities in this \(periodName)",
                    message: "Walks, play, training, and quieter moments show up here once they are logged."
                )
            }
        }

        Section("Weight") {
            if weightPoints.count >= 2 {
                Chart(weightPoints) { entry in
                    LineMark(x: .value("Date", entry.loggedAt), y: .value("kg", entry.kilograms))
                        .foregroundStyle(AppTheme.health)
                    PointMark(x: .value("Date", entry.loggedAt), y: .value("kg", entry.kilograms))
                        .foregroundStyle(AppTheme.health)
                }
                .frame(height: 180)
                .accessibilityLabel("Weight over this \(periodName)")
            }
            metric("Change", signedKg(careReport.weightDeltaKg), tint: AppTheme.health)
            metric("Direction", CareAnalytics.weightTrend(scopedWeights).direction, tint: AppTheme.health)
            if let latest = careReport.latestWeightKg {
                metric("Latest", String(format: "%.2f kg", latest), tint: AppTheme.health)
            }
        }

    }

    @ViewBuilder
    private var completedDetail: some View {
        if careReport.tasksScheduled == 0 {
            Section {
                EmptyStateView(
                    systemImage: "checkmark.circle",
                    title: "No tasks were due",
                    message: "Completed and missed tasks show up here once something is scheduled in this \(periodName)."
                )
            }
        } else {
            Section("Tasks") {
                metric("Completed", "\(careReport.tasksDone)", tint: AppTheme.tasks)
                metric("Missed", "\(careReport.tasksMissed)", tint: AppTheme.tasks)
                metric("Due", "\(careReport.tasksScheduled)", tint: AppTheme.tasks)
                metric("Completion", "\(careReport.completionPercent)%", tint: AppTheme.tasks)
                metric("Streak", "\(CareAnalytics.currentStreak(tasks: scopedTasks)) days", tint: AppTheme.tasks)
            }
        }
    }

    @ViewBuilder
    private var calorieDetail: some View {
        if periodMeals.isEmpty {
            Section {
                EmptyStateView(
                    systemImage: "flame",
                    title: "No meals in this \(periodName)",
                    message: "Logged meals show calories here, in kcal, beside the daily estimate."
                )
            }
        } else {
            Section("Calories") {
                metric("Eaten", MeasureText.calories(periodCalories), tint: AppTheme.nutrition)
                metric("Typical meal", MeasureText.calories(periodCalories / Double(periodMeals.count)), tint: AppTheme.nutrition)
                metric("Amount", MeasureText.mass(grams: periodGrams), tint: AppTheme.nutrition)
                metric("Meals", "\(periodMeals.count)", tint: AppTheme.nutrition)
                if let recommended = careReport.recommendedDaily {
                    metric("Daily estimate", "\(recommended) kcal", tint: AppTheme.nutrition)
                }
            }
        }
    }

    @ViewBuilder
    private var foodDetail: some View {
        if foodShares.isEmpty {
            Section {
                EmptyStateView(
                    systemImage: "fork.knife",
                    title: "No foods in this \(periodName)",
                    message: "Each food keeps its own meals, weight, and calories."
                )
            }
        } else {
            Section("Foods") {
                ForEach(foodShares) { food in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(food.name)
                        Text("\(food.meals) \(food.meals == 1 ? "meal" : "meals") · \(MeasureText.mass(grams: food.grams)) · \(MeasureText.calories(food.calories))")
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                    .accessibilityElement(children: .combine)
                }
            }
        }
    }

    @ViewBuilder
    private var filterChart: some View {
        if let activity {
            if focus.days.contains(where: { $0.sessions > 0 }) {
                activityChart
            }
        } else if focus.sessions > 0 {
            Chart(focus.counts, id: \.0) { item in
                BarMark(x: .value("Times", item.1), y: .value("Activity", item.0.rawValue))
                    .foregroundStyle(AppTheme.behavior)
            }
            .frame(height: chartHeight(focus.counts.count))
            .accessibilityLabel("How often each activity was logged")
        }
    }

    private var activityChart: some View {
        let usesHours = focus.minutes >= 60
        let usesTime = focus.minutes > 0
        return Chart(focus.days) { point in
            BarMark(
                x: .value("Day", point.day, unit: .day),
                y: .value(
                    chartUnit(usesHours: usesHours, usesTime: usesTime),
                    chartValue(point, usesHours: usesHours, usesTime: usesTime)
                )
            )
            .foregroundStyle(AppTheme.analytics)
        }
        .frame(height: 180)
        .chartXAxis {
            AxisMarks(values: .stride(by: .day, count: period > 7 ? 7 : 1)) { value in
                AxisGridLine()
                AxisValueLabel {
                    if let date = value.as(Date.self) {
                        Text(period > 7 ? date.formatted(.dateTime.day()) : date.formatted(.dateTime.weekday(.narrow)))
                    }
                }
            }
        }
        .accessibilityLabel(usesHours ? "Hours each day" : usesTime ? "Minutes each day" : "Sessions each day")
    }

    private func chartUnit(usesHours: Bool, usesTime: Bool) -> String {
        if usesHours { return "Hours" }
        if usesTime { return "Minutes" }
        return "Sessions"
    }

    private func chartValue(_ point: CareAnalytics.DayPoint, usesHours: Bool, usesTime: Bool) -> Double {
        if usesHours { return Double(point.minutes) / 60 }
        if usesTime { return Double(point.minutes) }
        return Double(point.sessions)
    }

    private var allSessions: Int {
        scopedBehaviors.filter { $0.occurredAt >= windowStart && $0.occurredAt <= Date() }.count
    }

    private var focus: CareAnalytics.ActivityFocus {
        CareAnalytics.activityFocus(
            entries: scopedBehaviors,
            kind: activity,
            days: period,
            petName: subjectName
        )
    }

    private var careReport: CareAnalytics.PeriodReport {
        CareAnalytics.report(
            days: period,
            pet: subject,
            feedings: scopedFeedings,
            weights: scopedWeights,
            behaviors: scopedBehaviors,
            tasks: scopedTasks
        )
    }

    private var shownNotes: [String] {
        remoteNotes ?? focus.notes
    }

    private var periodName: String {
        period > 7 ? "month" : "week"
    }

    private var sectionTitle: String {
        if topic == .activities {
            return activity?.rawValue ?? "All activities"
        }
        return topic.rawValue
    }

    private var periodMeals: [FeedingEntry] {
        scopedFeedings.filter { $0.fedAt >= windowStart && $0.fedAt <= Date() }
    }

    private var periodCalories: Double {
        periodMeals.reduce(0) { $0 + ($1.calories ?? 0) }
    }

    private var periodGrams: Double {
        periodMeals.reduce(0) { $0 + $1.amountGrams }
    }

    private var foodShares: [CareAnalytics.FoodShare] {
        CareAnalytics.foodShares(periodMeals)
    }

    private var windowStart: Date {
        Date().addingTimeInterval(TimeInterval(-period * 86_400))
    }

    private var requestKey: String {
        "\(petId.uuidString)-\(period)-\(topic.rawValue)-\(activity?.rawValue ?? "all")"
    }

    private var subjectName: String {
        if petId == PetManager.allPetsId { return "Your pets" }
        return pets.pets.first { $0.id == petId }?.name ?? "Your pet"
    }

    private var subject: PetProfile? {
        pets.pets.first { $0.id == petId }
    }

    private var scopedBehaviors: [BehaviorEntry] {
        wellness.behaviors.filter { matches($0.petId) }
    }

    private var scopedFeedings: [FeedingEntry] {
        wellness.feedings.filter { matches($0.petId) }
    }

    private var scopedWeights: [WeightEntry] {
        wellness.weights.filter { matches($0.petId) }
    }

    private var scopedTasks: [CustomCareTask] {
        tasks.tasks.filter { petId == PetManager.allPetsId || $0.petId == petId }
    }

    private var weightPoints: [WeightEntry] {
        scopedWeights.filter { $0.loggedAt >= windowStart }.sorted { $0.loggedAt < $1.loggedAt }
    }

    private var recentEntries: [BehaviorEntry] {
        scopedBehaviors
            .filter { $0.occurredAt >= windowStart && $0.kind == activity }
            .sorted { $0.occurredAt > $1.occurredAt }
            .prefix(8)
            .map { $0 }
    }

    private func sessionCount(_ kind: BehaviorKind) -> Int {
        scopedBehaviors.filter { $0.kind == kind && $0.occurredAt >= windowStart && $0.occurredAt <= Date() }.count
    }

    private func matches(_ id: UUID?) -> Bool {
        petId == PetManager.allPetsId || id == petId
    }

    private func chartHeight(_ count: Int) -> CGFloat {
        CGFloat(max(count, 1) * 28 + 24)
    }

    private func metric(_ title: String, _ value: String, tint: Color = AppTheme.analytics) -> some View {
        MetricTile(title: title, value: value, tint: tint)
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
    }

    private func signedKg(_ value: Double?) -> String {
        guard let value else { return "Need two weigh-ins" }
        let prefix = value > 0 ? "+" : ""
        return prefix + String(format: "%.2f kg", value)
    }

    private func entryLine(_ entry: BehaviorEntry) -> String {
        var parts = [
            entry.occurredAt.formatted(date: .abbreviated, time: .shortened),
            MeasureText.duration(minutes: entry.durationMinutes)
        ]
        if !entry.mood.isEmpty { parts.append(entry.mood) }
        if !entry.location.isEmpty { parts.append(entry.location) }
        return parts.joined(separator: " · ")
    }

    private func loadNarrative() async {
        let key = requestKey
        remoteNotes = nil
        summaryNotes = []
        narrativeSource = nil
        guard auth.isSignedIn else {
            loadingNarrative = false
            return
        }
        loadingNarrative = true
        defer {
            if key == requestKey {
                loadingNarrative = false
            }
        }
        let body = InsightWindowBody(
            petId: petId == PetManager.allPetsId ? nil : petId,
            window: period > 7 ? "monthly" : "weekly",
            lens: topic.lens,
            activity: topic == .activities ? activity?.rawValue : nil
        )
        if let remote: APIBehaviorInsight = try? await APIClient.shared.send(
            "POST",
            path: "insights/behavior",
            body: body
        ), key == requestKey, !Task.isCancelled {
            remoteNotes = remote.highlights
            narrativeSource = remote.source == "model" ? "Rewritten from your logs" : "From your account"
        }
        if let summary: APIHealthSummary = try? await APIClient.shared.send(
            "POST",
            path: "insights/summary",
            body: body
        ), key == requestKey, !Task.isCancelled {
            summaryNotes = summary.highlights
        }
    }
}

private enum InsightTopic: String, CaseIterable, Identifiable {
    case activities = "Activities"
    case completed = "Completed"
    case calories = "Calories"
    case foods = "Foods"

    var id: String { rawValue }

    var lens: String { rawValue.lowercased() }

    var symbol: String {
        switch self {
        case .activities: return "figure.walk"
        case .completed: return "checkmark.circle"
        case .calories: return "flame"
        case .foods: return "fork.knife"
        }
    }

    var tint: Color {
        switch self {
        case .activities: return AppTheme.analytics
        case .completed: return AppTheme.tasks
        case .calories, .foods: return AppTheme.nutrition
        }
    }

    var footer: String {
        switch self {
        case .activities:
            return "Time is shown in minutes, or in hours once a session reaches an hour."
        case .completed:
            return "Completed counts the tasks that were due and finished in this window."
        case .calories:
            return "Calories stay in kcal. Meal size is shown in grams, or kilograms at 1 kg and above."
        case .foods:
            return "Each food keeps its meals, weight, and calories in the same units."
        }
    }
}

private struct InsightWindowBody: Encodable {
    var petId: UUID?
    var window: String
    var lens: String
    var activity: String?
}

#Preview {
    NavigationStack {
        ActivityInsightsView()
    }
    .environmentObject(PetManager.shared)
    .environmentObject(WellnessStore.shared)
    .environmentObject(CareTaskStore.shared)
    .environmentObject(AuthSession.shared)
}
