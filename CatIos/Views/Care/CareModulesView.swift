import Charts
import SwiftUI

struct ModuleLink: View {
    let title: String
    let systemImage: String
    let tint: Color

    var body: some View {
        HStack(spacing: AppTheme.spacingM) {
            EnchantedIconBadge(systemImage: systemImage, tint: tint, size: 40)
            Text(title)
                .font(AppTheme.headlineFont())
                .foregroundStyle(AppTheme.textPrimary)
        }
    }
}

struct InsightDisclaimer: View {
    var body: some View {
        Text(CareInsights.disclaimer)
            .font(.footnote)
            .foregroundStyle(AppTheme.textSecondary)
            .accessibilityLabel(CareInsights.disclaimer)
    }
}

struct MetricTile: View {
    let title: String
    let value: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacingXS) {
            Text(title)
                .font(AppTheme.captionFont())
                .foregroundStyle(AppTheme.textSecondary)
            Text(value)
                .font(.system(.title3, design: .rounded).weight(.bold))
                .foregroundStyle(tint)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppTheme.spacingM)
        .cardStyle(cornerRadius: AppTheme.cornerRadiusLarge)
        .accessibilityElement(children: .combine)
    }
}

struct NutritionView: View {
    @EnvironmentObject private var pets: PetManager
    @EnvironmentObject private var wellness: WellnessStore
    @EnvironmentObject private var tasks: CareTaskStore
    @EnvironmentObject private var auth: AuthSession
    @EnvironmentObject private var analytics: AnalyticsStore
    @EnvironmentObject private var householdSync: HouseholdSync

    @State private var petId = PetManager.shared.currentPet.id
    @State private var query = ""
    @State private var favoritesOnly = false
    @State private var showFood = false
    @State private var showFeeding = false
    @State private var activity = "moderate"
    @State private var meals = 2
    @State private var insight: APINutritionInsight?
    @State private var loadingInsight = false

    private var pet: PetProfile? { pets.pets.first { $0.id == petId } }
    private var visibleFoods: [FoodItem] { wellness.foods(matching: query, favoritesOnly: favoritesOnly) }
    private var history: [FeedingEntry] {
        wellness.feedings.filter { petId == PetManager.allPetsId || $0.petId == petId }.sorted { $0.fedAt > $1.fedAt }
    }

    var body: some View {
        List {
            Section {
                PetScopePicker(selection: $petId, pets: pets.pets)
                Picker("Activity", selection: $activity) {
                    Text("Low").tag("low")
                    Text("Moderate").tag("moderate")
                    Text("High").tag("high")
                }
                Stepper("Meals a day: \(meals)", value: $meals, in: 1...6)
                Button(loadingInsight ? "Estimating…" : "Estimate portions") {
                    Task { await estimate() }
                }
                .disabled(loadingInsight || pet == nil && petId != PetManager.allPetsId)
                if loadingInsight {
                    ProgressView()
                        .accessibilityLabel("Estimating portions")
                }
                if let insight {
                    Text("\(insight.dailyCalories) kcal / day")
                        .font(.headline)
                        .foregroundStyle(AppTheme.nutrition)
                    Text("\(insight.caloriesPerMeal) kcal per meal")
                    if let grams = insight.suggestedGramsPerServing {
                        Text("About \(grams) g per serving")
                    }
                    ForEach(insight.notes, id: \.self) { note in
                        Text(note)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    InsightDisclaimer()
                }
            } header: {
                Text("Portion estimate")
            }

            Section("This week") {
                nutritionSummary(days: 7)
            }
            Section("This month") {
                nutritionSummary(days: 30)
            }

            Section {
                TextField("Search foods", text: $query)
                Toggle("Favorites", isOn: $favoritesOnly)
            }

            Section("Foods") {
                if visibleFoods.isEmpty {
                    EmptyStateView(
                        systemImage: "fork.knife",
                        title: "No foods yet",
                        message: "Add a food you use, then log each meal against it.",
                        actionTitle: "Add Food",
                        action: { showFood = true }
                    )
                } else {
                    ForEach(visibleFoods) { food in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(food.name).font(.headline)
                                Spacer()
                                if food.isFavorite {
                                    Image(systemName: "heart.fill").foregroundStyle(AppTheme.nutrition).accessibilityLabel("Favorite")
                                }
                            }
                            Text([food.brand, food.productName, food.category.rawValue].filter { !$0.isEmpty }.joined(separator: " · "))
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            if let calories = food.caloriesPer100g {
                                Text("\(calories.formatted()) kcal / 100 g")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .swipeActions {
                            if householdSync.canMutate {
                                Button("Favorite") {
                                    toggleFavorite(food)
                                }
                                .tint(AppTheme.nutrition)
                                Button("Delete", role: .destructive) {
                                    wellness.foods.removeAll { $0.id == food.id }
                                }
                            }
                        }
                    }
                }
            }

            Section("Feeding history") {
                if history.isEmpty {
                    Text("Meals you log will stay here.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(history) { entry in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(entry.foodName).font(.headline)
                            Text("\(entry.fedAt.formatted(date: .abbreviated, time: .shortened)) · \(MeasureText.mass(grams: entry.amountGrams))")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            if let calories = entry.calories {
                                Text(MeasureText.calories(calories))
                                    .font(.caption)
                                    .foregroundStyle(AppTheme.nutrition)
                            }
                        }
                        .swipeActions {
                            if householdSync.canMutate {
                                Button("Delete", role: .destructive) {
                                    wellness.feedings.removeAll { $0.id == entry.id }
                                }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Nutrition")
        .toolbar {
            if householdSync.canMutate {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button("Add Food", systemImage: "plus") { showFood = true }
                    Button("Log Meal", systemImage: "fork.knife") { showFeeding = true }
                    Button("Feeding Reminder", systemImage: "bell") { addFeedingReminder() }
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Add nutrition")
            }
            }
        }
        .sheet(isPresented: $showFood) {
            FoodEditorView(petId: resolvedPetId)
                .environmentObject(wellness)
                .environmentObject(pets)
                .environmentObject(auth)
        }
        .sheet(isPresented: $showFeeding) { FeedingEditor(petId: resolvedPetId) }
        .task(id: petId) { await analytics.load(petId: petId) }
    }

    private func nutritionSummary(days: Int) -> some View {
        let period = days == 7 ? analytics.report?.week : analytics.report?.month
        return VStack(alignment: .leading, spacing: AppTheme.spacingS) {
            if let period {
                LabeledContent("Calories eaten", value: MeasureText.calories(period.calories))
                if let recommended = period.recommendedDaily {
                    LabeledContent("Recommended", value: "\(recommended) kcal / day")
                }
                LabeledContent("Meals", value: "\(period.meals)")
                LabeledContent("Days fed", value: "\(period.feedingDays) of \(days)")
                if let food = period.foods.first {
                    LabeledContent("Most used food", value: food.name)
                }
                if let brand = period.brands.first {
                    LabeledContent("Most used brand", value: brand.name)
                }
            } else {
                ServerAnalyticsStatus()
            }
        }
        .foregroundStyle(AppTheme.nutrition)
    }

    private var resolvedPetId: UUID? {
        petId == PetManager.allPetsId ? pets.currentPet.id : petId
    }

    private func toggleFavorite(_ food: FoodItem) {
        guard let index = wellness.foods.firstIndex(where: { $0.id == food.id }) else { return }
        wellness.foods[index].isFavorite.toggle()
    }

    private func addFeedingReminder() {
        guard let pet = pets.pets.first(where: { $0.id == resolvedPetId }) ?? pets.pets.first else { return }
        tasks.tasks.insert(
            CustomCareTask(
                petId: pet.id,
                title: "Feed \(pet.name)",
                timeText: "08:00 AM",
                frequency: .daily,
                isCompleted: false,
                alarmEnabled: true,
                emojiIcon: "🍽️",
                startDate: Date(),
                taskKind: .feeding
            ),
            at: 0
        )
    }

    private func estimate() async {
        let subject = pet ?? pets.currentPet
        let latest = wellness.weights.filter { $0.petId == subject.id }.max { $0.loggedAt < $1.loggedAt }
        let weight = latest?.kilograms ?? 4
        let food = visibleFoods.first ?? wellness.foods.first
        loadingInsight = true
        defer { loadingInsight = false }
        if auth.isSignedIn {
            let body = NutritionInsightBody(
                petId: subject.id,
                species: subject.petType.rawValue,
                breed: subject.breed,
                sex: subject.gender.rawValue,
                ageYears: subject.age.years,
                ageMonths: subject.age.months,
                weightKg: weight,
                activityLevel: activity,
                mealsPerDay: meals,
                caloriesPer100g: food?.caloriesPer100g,
                proteinPer100g: food?.protein,
                fatPer100g: food?.fat,
                fiberPer100g: food?.fiber
            )
            if let remote: APINutritionInsight = try? await APIClient.shared.send("POST", path: "insights/nutrition", body: body) {
                insight = remote
                return
            }
        }
        let local = CareInsights.portion(
            species: subject.petType.rawValue,
            ageYears: subject.age.years,
            weightKg: weight,
            activity: activity,
            meals: meals,
            caloriesPer100g: food?.caloriesPer100g,
            proteinPer100g: food?.protein,
            fatPer100g: food?.fat,
            fiberPer100g: food?.fiber
        )
        insight = APINutritionInsight(
            disclaimer: CareInsights.disclaimer,
            source: "estimate",
            dailyCalories: local.dailyCalories,
            caloriesPerMeal: local.caloriesPerMeal,
            suggestedGramsPerServing: local.gramsPerServing,
            estimatedCalories: local.dailyCalories,
            estimatedProteinG: local.proteinGrams,
            estimatedFatG: local.fatGrams,
            estimatedFiberG: local.fiberGrams,
            notes: local.notes
        )
    }
}

private struct NutritionInsightBody: Encodable {
    var petId: UUID
    var species: String
    var breed: String
    var sex: String
    var ageYears: Int
    var ageMonths: Int
    var weightKg: Double
    var activityLevel: String
    var mealsPerDay: Int
    var caloriesPer100g: Double?
    var proteinPer100g: Double?
    var fatPer100g: Double?
    var fiberPer100g: Double?
}

private struct FeedingEditor: View {
    @EnvironmentObject private var wellness: WellnessStore
    @Environment(\.dismiss) private var dismiss
    var petId: UUID?

    @EnvironmentObject private var pets: PetManager
    @EnvironmentObject private var auth: AuthSession

    var body: some View {
        MealLogSheet(petId: petId, title: "Log Meal") { entry in
            wellness.feedings.insert(entry, at: 0)
            dismiss()
        }
        .environmentObject(wellness)
        .environmentObject(pets)
        .environmentObject(auth)
    }
}

struct WeightView: View {
    @EnvironmentObject private var pets: PetManager
    @EnvironmentObject private var wellness: WellnessStore
    @EnvironmentObject private var tasks: CareTaskStore
    @EnvironmentObject private var analytics: AnalyticsStore
    @EnvironmentObject private var householdSync: HouseholdSync
    @State private var petId = PetManager.shared.currentPet.id
    @State private var showLog = false

    private var logs: [WeightEntry] {
        wellness.weights
            .filter { $0.petId == petId || petId == PetManager.allPetsId }
            .sorted { $0.loggedAt < $1.loggedAt }
    }

    var body: some View {
        List {
            Section {
                PetScopePicker(selection: $petId, pets: pets.pets)
            }
            Section("Change") {
                let points = analytics.report?.weights ?? []
                if points.count >= 2 {
                    Chart(points) { entry in
                        LineMark(x: .value("Date", entry.loggedAt), y: .value("kg", entry.kilograms))
                            .foregroundStyle(AppTheme.health)
                    }
                    .frame(height: 180)
                    .accessibilityLabel("Weight trend from your account")
                }
                LabeledContent("This week", value: signed(analytics.report?.week.weightDeltaKg))
                LabeledContent("This month", value: signed(analytics.report?.month.weightDeltaKg))
                LabeledContent("Direction", value: analytics.report?.week.weightDirection ?? "Loading")
                ServerAnalyticsStatus()
            }
            Section("History") {
                if logs.isEmpty {
                    EmptyStateView(
                        systemImage: "scalemass",
                        title: "No weights yet",
                        message: "A weekly weigh-in makes the trend easier to see.",
                        actionTitle: householdSync.canMutate ? "Log Weight" : nil,
                        action: householdSync.canMutate ? { showLog = true } : nil
                    )
                } else {
                    ForEach(logs.reversed()) { entry in
                        VStack(alignment: .leading) {
                            Text("\(entry.weight.formatted()) \(entry.unit)")
                                .font(.headline)
                            Text(entry.loggedAt.formatted(date: .abbreviated, time: .omitted))
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            if !entry.notes.isEmpty {
                                Text(entry.notes).font(.caption)
                            }
                        }
                        .swipeActions {
                            if householdSync.canMutate {
                                Button("Delete", role: .destructive) {
                                    wellness.weights.removeAll { $0.id == entry.id }
                                }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Weight")
        .toolbar {
            if householdSync.canMutate {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button("Log Weight", systemImage: "plus") { showLog = true }
                    Button("Weekly Reminder", systemImage: "bell") { addReminder(frequency: .weekly) }
                    Button("Monthly Reminder", systemImage: "calendar") { addReminder(frequency: .monthly) }
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Add weight")
            }
            }
        }
        .sheet(isPresented: $showLog) { WeightEditor(petId: petId == PetManager.allPetsId ? pets.currentPet.id : petId) }
        .task(id: petId) { await analytics.load(petId: petId) }
    }

    private func signed(_ value: Double?) -> String {
        guard let value else { return "Need two weigh-ins" }
        let prefix = value > 0 ? "+" : ""
        return prefix + String(format: "%.2f kg", value)
    }

    private func addReminder(frequency: TaskFrequency) {
        let target = petId == PetManager.allPetsId ? pets.currentPet.id : petId
        guard let pet = pets.pets.first(where: { $0.id == target }) else { return }
        tasks.tasks.insert(
            CustomCareTask(
                petId: pet.id,
                title: "Weigh \(pet.name)",
                timeText: "09:00 AM",
                frequency: frequency,
                selectedDays: [1],
                isCompleted: false,
                alarmEnabled: true,
                emojiIcon: "⚖️",
                startDate: Date(),
                taskKind: .weight
            ),
            at: 0
        )
    }
}

private struct WeightEditor: View {
    @EnvironmentObject private var wellness: WellnessStore
    @Environment(\.dismiss) private var dismiss
    var petId: UUID
    @State private var weight = ""
    @State private var unit = "kg"
    @State private var when = Date()
    @State private var notes = ""

    var body: some View {
        NavigationStack {
            Form {
                TextField("Weight", text: $weight)
                    .keyboardType(.decimalPad)
                Picker("Unit", selection: $unit) {
                    Text("kg").tag("kg")
                    Text("lb").tag("lb")
                }
                DatePicker("Date", selection: $when, displayedComponents: .date)
                TextField("Notes", text: $notes, axis: .vertical)
            }
            .navigationTitle("Log Weight")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        guard let value = Double(weight), value > 0 else { return }
                        wellness.weights.append(WeightEntry(petId: petId, weight: value, unit: unit, loggedAt: when, notes: notes))
                        dismiss()
                    }
                    .disabled(Double(weight) == nil)
                }
            }
        }
    }
}

struct BehaviorView: View {
    @EnvironmentObject private var pets: PetManager
    @EnvironmentObject private var wellness: WellnessStore
    @EnvironmentObject private var analytics: AnalyticsStore
    @EnvironmentObject private var householdSync: HouseholdSync
    @State private var petId = PetManager.shared.currentPet.id
    @State private var draftKind: BehaviorKind?

    private var entries: [BehaviorEntry] {
        wellness.behaviors
            .filter { petId == PetManager.allPetsId || $0.petId == petId }
            .sorted { $0.occurredAt > $1.occurredAt }
    }

    var body: some View {
        List {
            Section {
                PetScopePicker(selection: $petId, pets: pets.pets)
            }
            Section("This week") {
                behaviorSummary(entries, days: 7)
            }
            Section("This month") {
                behaviorSummary(entries, days: 30)
            }
            if householdSync.canMutate {
            Section("Log") {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(BehaviorKind.allCases) { kind in
                            Button {
                                guard householdSync.canMutate else { return }
                                draftKind = kind
                            } label: {
                                Label(kind.rawValue, systemImage: kind.symbol)
                                    .font(.caption)
                            }
                            .buttonStyle(.bordered)
                            .tint(AppTheme.behavior)
                        }
                    }
                }
            }
            }
            Section("History") {
                if entries.isEmpty {
                    EmptyStateView(
                        systemImage: "pawprint",
                        title: "No activities yet",
                        message: "Park visits, training, grooming, and quieter moments all belong here."
                    )
                } else {
                    ForEach(entries) { entry in
                        VStack(alignment: .leading, spacing: 2) {
                            Label(entry.title.isEmpty ? entry.kind.rawValue : entry.title, systemImage: entry.icon)
                            Text("\(entry.occurredAt.formatted(date: .abbreviated, time: .shortened)) · \(MeasureText.duration(minutes: entry.durationMinutes))")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            if !entry.mood.isEmpty || !entry.location.isEmpty {
                                Text([entry.mood, entry.location].filter { !$0.isEmpty }.joined(separator: " · "))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .swipeActions {
                            if householdSync.canMutate {
                                Button("Delete", role: .destructive) {
                                    wellness.behaviors.removeAll { $0.id == entry.id }
                                }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Behavior")
        .task(id: petId) { await analytics.load(petId: petId) }
        .sheet(item: $draftKind) { kind in
            BehaviorEditor(kind: kind, petId: petId == PetManager.allPetsId ? pets.currentPet.id : petId)
        }
    }

    private func behaviorSummary(_ entries: [BehaviorEntry], days: Int) -> some View {
        let period = days == 7 ? analytics.report?.week : analytics.report?.month
        return VStack(alignment: .leading, spacing: AppTheme.spacingS) {
            if let period {
                LabeledContent("Walks", value: "\(period.walkCount)")
                LabeledContent("Park visits", value: "\(period.parkCount)")
                LabeledContent("Training", value: "\(period.trainingCount)")
                LabeledContent("Social", value: "\(period.socialCount)")
                LabeledContent("Positive streak", value: "\(period.positiveStreak) days")
                ForEach(period.behaviors.prefix(6), id: \.name) { item in
                    Text("\(item.name) · \(item.count)")
                }
            } else {
                ServerAnalyticsStatus()
            }
        }
        .foregroundStyle(AppTheme.behavior)
    }
}

private struct BehaviorEditor: View {
    @EnvironmentObject private var wellness: WellnessStore
    @Environment(\.dismiss) private var dismiss
    var kind: BehaviorKind
    var petId: UUID
    @State private var title = ""
    @State private var when = Date()
    @State private var minutes = 15
    @State private var durationUnit = "Minutes"
    @State private var mood = ""
    @State private var severity = 1
    @State private var location = ""
    @State private var notes = ""

    var body: some View {
        NavigationStack {
            Form {
                TextField("Title", text: $title, prompt: Text(kind.rawValue))
                DatePicker("When", selection: $when)
                Picker("Duration unit", selection: $durationUnit) {
                    Text("Minutes").tag("Minutes")
                    Text("Hours").tag("Hours")
                }
                .pickerStyle(.segmented)
                Stepper(MeasureText.duration(minutes: minutes), value: $minutes, in: 0...12 * 60, step: durationUnit == "Hours" ? 60 : 5)
                    .onChange(of: durationUnit) { _, unit in
                        guard unit == "Hours" else { return }
                        let hours = max(minutes == 0 ? 0 : 1, Int((Double(minutes) / 60).rounded()))
                        minutes = min(12 * 60, hours * 60)
                    }
                TextField("Mood", text: $mood)
                Stepper("Severity: \(severity)", value: $severity, in: 1...5)
                TextField("Location", text: $location)
                TextField("Notes", text: $notes, axis: .vertical)
            }
            .navigationTitle(kind.rawValue)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        wellness.behaviors.insert(
                            BehaviorEntry(
                                petId: petId,
                                kind: kind,
                                title: title.isEmpty ? kind.rawValue : title,
                                occurredAt: when,
                                durationMinutes: minutes,
                                notes: notes,
                                mood: mood,
                                severity: severity,
                                location: location,
                                icon: kind.symbol,
                                colorHex: kind.colorHex
                            ),
                            at: 0
                        )
                        dismiss()
                    }
                }
            }
        }
    }
}

struct ServerAnalyticsStatus: View {
    @EnvironmentObject private var analytics: AnalyticsStore

    var body: some View {
        if analytics.isLoading {
            ProgressView("Loading from your account")
        } else if let message = analytics.message {
            Text(message)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }
}
