import SwiftUI

struct MealLogDraft {
    var foodId: UUID?
    var foodSearch: String = ""
    var when: Date = Date()
    var amount: String = ""
    var massUnit: String = "g"
    var calories: String = ""
    var caloriesManuallyEdited = false
    var notes: String = ""
    var aiNotes: [String] = []

    var trimmedFoodName: String {
        foodSearch.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func storedGrams() -> Double? {
        guard let value = Double(amount.replacingOccurrences(of: ",", with: ".")), value > 0 else { return nil }
        return massUnit == "kg" ? value * 1000 : value
    }

    func selectedFood(in foods: [FoodItem]) -> FoodItem? {
        foods.first { $0.id == foodId }
    }

    func suggestedCalories(foods: [FoodItem]) -> Double? {
        guard let grams = storedGrams() else { return nil }
        let food = selectedFood(in: foods)
        return CareInsights.calories(grams: grams, per100g: food?.caloriesPer100g)
    }

    func storedCalories(foods: [FoodItem]) -> Double? {
        if let manual = Double(calories.replacingOccurrences(of: ",", with: ".")), manual > 0 {
            return manual
        }
        return suggestedCalories(foods: foods)
    }

    func canSave(foods: [FoodItem]) -> Bool {
        !resolvedFoodName(in: foods).isEmpty && storedGrams() != nil && storedCalories(foods: foods) != nil
    }

    func resolvedFoodName(in foods: [FoodItem]) -> String {
        selectedFood(in: foods)?.name ?? trimmedFoodName
    }

    func makeEntry(petId: UUID?, foods: [FoodItem]) -> FeedingEntry? {
        guard let grams = storedGrams(), let kcal = storedCalories(foods: foods) else { return nil }
        let food = selectedFood(in: foods)
        let foodName = resolvedFoodName(in: foods)
        guard !foodName.isEmpty else { return nil }
        return FeedingEntry(
            petId: petId,
            foodId: food?.id,
            fedAt: when,
            foodName: foodName,
            brand: food?.brand ?? "",
            amountGrams: grams,
            calories: kcal,
            notes: notes.trimmingCharacters(in: .whitespacesAndNewlines)
        )
    }

    mutating func refreshCalories(foods: [FoodItem]) {
        guard !caloriesManuallyEdited else { return }
        if let suggested = suggestedCalories(foods: foods) {
            calories = String(Int(suggested.rounded()))
        }
    }

    mutating func selectFood(_ food: FoodItem) {
        foodId = food.id
        foodSearch = food.name
        refreshCalories(foods: [food])
    }

    mutating func applySuggestion(_ suggestion: APIFoodSuggest, existingFoods: [FoodItem]) -> FoodItem? {
        foodSearch = suggestion.name
        amount = String(suggestion.suggestedGrams)
        massUnit = "g"
        calories = String(suggestion.suggestedCalories)
        caloriesManuallyEdited = true
        aiNotes = suggestion.notes

        if let existing = existingFoods.first(where: { $0.name.caseInsensitiveCompare(suggestion.name) == .orderedSame }) {
            foodId = existing.id
            return nil
        }

        let category = NutritionCategory.allCases.first { $0.rawValue == suggestion.category } ?? .other
        let food = FoodItem(
            name: suggestion.name,
            brand: suggestion.brand,
            productName: suggestion.productName,
            category: category,
            caloriesPer100g: suggestion.caloriesPer100g,
            protein: suggestion.proteinPer100g,
            fat: suggestion.fatPer100g,
            fiber: suggestion.fiberPer100g
        )
        foodId = food.id
        return food
    }
}

struct MealLogForm: View {
    @EnvironmentObject private var wellness: WellnessStore
    @EnvironmentObject private var pets: PetManager
    @EnvironmentObject private var auth: AuthSession

    @Binding var draft: MealLogDraft
    let petId: UUID?

    @State private var showFoodEditor = false
    @State private var loadingSuggestion = false

    private var matchingFoods: [FoodItem] {
        wellness.foods(matching: draft.foodSearch, favoritesOnly: false)
    }

    var body: some View {
        Group {
            Section("Food") {
                HStack(spacing: AppTheme.spacingS) {
                    TextField("Food name", text: $draft.foodSearch)
                        .textInputAutocapitalization(.words)
                        .onChange(of: draft.foodSearch) { _, newValue in
                            if let food = wellness.foods.first(where: {
                                $0.name.caseInsensitiveCompare(newValue.trimmingCharacters(in: .whitespacesAndNewlines)) == .orderedSame
                            }) {
                                draft.foodId = food.id
                            } else if draft.selectedFood(in: wellness.foods)?.name != newValue {
                                draft.foodId = nil
                            }
                            draft.refreshCalories(foods: wellness.foods)
                        }
                    Button {
                        Task { await suggestWithAI() }
                    } label: {
                        if loadingSuggestion {
                            ProgressView()
                        } else {
                            Image(systemName: "wand.and.stars")
                        }
                    }
                    .buttonStyle(.bordered)
                    .accessibilityLabel("AI autocomplete food and portion")
                    .disabled(loadingSuggestion || draft.trimmedFoodName.isEmpty)
                }

                if !matchingFoods.isEmpty {
                    ForEach(matchingFoods.prefix(5)) { food in
                        Button {
                            draft.selectFood(food)
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(food.name)
                                        .foregroundStyle(AppTheme.textPrimary)
                                    Text(foodSubtitle(food))
                                        .font(.caption)
                                        .foregroundStyle(AppTheme.textSecondary)
                                }
                                Spacer()
                                if draft.foodId == food.id {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(AppTheme.nutrition)
                                }
                            }
                        }
                    }
                }

                Button {
                    showFoodEditor = true
                } label: {
                    Label("Add New Food", systemImage: "plus.circle")
                }
            }

            if !draft.aiNotes.isEmpty {
                Section("AI suggestion") {
                    ForEach(draft.aiNotes, id: \.self) { note in
                        Text(note)
                            .font(AppTheme.captionFont())
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                    InsightDisclaimer()
                }
            }

            Section("Amount") {
                HStack {
                    TextField(draft.massUnit == "kg" ? "Kilograms" : "Grams", text: $draft.amount)
                        .keyboardType(.decimalPad)
                    Picker("Unit", selection: $draft.massUnit) {
                        Text("g").tag("g")
                        Text("kg").tag("kg")
                    }
                    .pickerStyle(.segmented)
                    .frame(maxWidth: 120)
                }
                .onChange(of: draft.amount) { _, _ in
                    draft.refreshCalories(foods: wellness.foods)
                }
                .onChange(of: draft.massUnit) { _, _ in
                    draft.refreshCalories(foods: wellness.foods)
                }
            }

            Section {
                TextField("Calories (kcal)", text: $draft.calories)
                    .keyboardType(.decimalPad)
                    .onChange(of: draft.calories) { _, _ in
                        draft.caloriesManuallyEdited = true
                    }
                if let suggested = draft.suggestedCalories(foods: wellness.foods), !draft.caloriesManuallyEdited {
                    Text("Estimated \(MeasureText.calories(suggested)) from the food label")
                        .font(AppTheme.captionFont())
                        .foregroundStyle(AppTheme.textSecondary)
                } else if draft.selectedFood(in: wellness.foods)?.caloriesPer100g == nil {
                    Text("Use AI suggest or enter calories manually.")
                        .font(AppTheme.captionFont())
                        .foregroundStyle(AppTheme.textSecondary)
                }
            } header: {
                Text("Calories")
            }

            Section("When") {
                DatePicker("Fed at", selection: $draft.when)
            }

            Section("Notes") {
                TextField("Optional notes", text: $draft.notes, axis: .vertical)
            }
        }
        .sheet(isPresented: $showFoodEditor) {
            FoodEditorView(initialName: draft.trimmedFoodName, petId: petId) { food in
                draft.selectFood(food)
            }
            .environmentObject(wellness)
            .environmentObject(pets)
            .environmentObject(auth)
        }
    }

    private func foodSubtitle(_ food: FoodItem) -> String {
        var parts = [food.brand, food.category.rawValue].filter { !$0.isEmpty }
        if let per100 = food.caloriesPer100g {
            parts.append("\(Int(per100)) kcal/100g")
        }
        return parts.joined(separator: " · ")
    }

    private func suggestWithAI() async {
        loadingSuggestion = true
        defer { loadingSuggestion = false }
        let suggestion = await FoodSuggestionService.suggest(
            query: draft.trimmedFoodName,
            brand: draft.selectedFood(in: wellness.foods)?.brand ?? "",
            context: suggestionContext(),
            signedIn: auth.isSignedIn
        )
        var next = draft
        if let food = next.applySuggestion(suggestion, existingFoods: wellness.foods) {
            wellness.foods.insert(food, at: 0)
        }
        draft = next
    }

    private func suggestionContext() -> FoodSuggestionService.Context {
        let subject = pets.pets.first { $0.id == petId } ?? pets.currentPet
        let latest = wellness.weights.filter { $0.petId == subject.id }.max { $0.loggedAt < $1.loggedAt }
        return FoodSuggestionService.Context(
            petId: subject.id,
            species: subject.petType.rawValue,
            breed: subject.breed,
            ageYears: subject.age.years,
            weightKg: latest?.kilograms ?? 4,
            activityLevel: "moderate",
            mealsPerDay: 2
        )
    }
}

struct MealLogSheet: View {
    @EnvironmentObject private var wellness: WellnessStore
    @EnvironmentObject private var pets: PetManager
    @EnvironmentObject private var auth: AuthSession
    @Environment(\.dismiss) private var dismiss

    let petId: UUID?
    let title: String
    let onSave: (FeedingEntry) -> Void

    @State private var draft = MealLogDraft()

    init(petId: UUID?, title: String = "Log Meal", when: Date = Date(), onSave: @escaping (FeedingEntry) -> Void) {
        self.petId = petId
        self.title = title
        self.onSave = onSave
        _draft = State(initialValue: MealLogDraft(when: when))
    }

    var body: some View {
        NavigationStack {
            Form {
                MealLogForm(draft: $draft, petId: petId)
            }
            .navigationTitle(title)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(!draft.canSave(foods: wellness.foods))
                }
            }
        }
        .environmentObject(wellness)
        .environmentObject(pets)
        .environmentObject(auth)
    }

    private func save() {
        guard let entry = draft.makeEntry(petId: petId, foods: wellness.foods) else { return }
        onSave(entry)
        dismiss()
    }
}
