import SwiftUI

struct FoodEditorView: View {
    @EnvironmentObject private var wellness: WellnessStore
    @EnvironmentObject private var pets: PetManager
    @EnvironmentObject private var auth: AuthSession
    @Environment(\.dismiss) private var dismiss

    var initialName: String = ""
    var petId: UUID?
    var onSaved: ((FoodItem) -> Void)?

    @State private var name = ""
    @State private var brand = ""
    @State private var product = ""
    @State private var category = NutritionCategory.dry
    @State private var calories = ""
    @State private var protein = ""
    @State private var fat = ""
    @State private var fiber = ""
    @State private var notes = ""
    @State private var favorite = false
    @State private var loadingSuggestion = false
    @State private var suggestionNotes: [String] = []

    var body: some View {
        NavigationStack {
            Form {
                Section("Food") {
                    TextField("Food name", text: $name)
                    TextField("Brand", text: $brand)
                    TextField("Product", text: $product)
                    Picker("Category", selection: $category) {
                        ForEach(NutritionCategory.allCases) { item in
                            Text(item.rawValue).tag(item)
                        }
                    }
                }

                Section {
                    TextField("Calories per 100 g", text: $calories)
                        .keyboardType(.decimalPad)
                    TextField("Protein g / 100 g", text: $protein)
                        .keyboardType(.decimalPad)
                    TextField("Fat g / 100 g", text: $fat)
                        .keyboardType(.decimalPad)
                    TextField("Fiber g / 100 g", text: $fiber)
                        .keyboardType(.decimalPad)
                    Button {
                        Task { await suggestWithAI() }
                    } label: {
                        Label(loadingSuggestion ? "Suggesting…" : "AI Autocomplete", systemImage: "wand.and.stars")
                    }
                    .disabled(loadingSuggestion || name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    if loadingSuggestion {
                        ProgressView()
                    }
                    ForEach(suggestionNotes, id: \.self) { note in
                        Text(note)
                            .font(AppTheme.captionFont())
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                } header: {
                    Text("Nutrition label")
                } footer: {
                    Text("AI fills typical calories and macros from the food name. You can edit before saving.")
                }

                Section("Notes") {
                    TextField("Optional notes", text: $notes, axis: .vertical)
                    Toggle("Favorite", isOn: $favorite)
                }
            }
            .navigationTitle("Add Food")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onAppear {
                if name.isEmpty {
                    name = initialName
                }
            }
        }
    }

    private func save() {
        let food = FoodItem(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            brand: brand,
            productName: product,
            category: category,
            caloriesPer100g: Double(calories),
            protein: Double(protein),
            fat: Double(fat),
            fiber: Double(fiber),
            notes: notes,
            isFavorite: favorite
        )
        wellness.foods.insert(food, at: 0)
        onSaved?(food)
        dismiss()
    }

    private func suggestWithAI() async {
        loadingSuggestion = true
        defer { loadingSuggestion = false }
        let suggestion = await FoodSuggestionService.suggest(
            query: name,
            brand: brand,
            context: suggestionContext(),
            signedIn: auth.isSignedIn
        )
        applySuggestion(suggestion)
    }

    private func applySuggestion(_ suggestion: APIFoodSuggest) {
        name = suggestion.name
        if brand.isEmpty { brand = suggestion.brand }
        if product.isEmpty { product = suggestion.productName }
        if let mapped = NutritionCategory.allCases.first(where: { $0.rawValue == suggestion.category }) {
            category = mapped
        }
        calories = String(Int(suggestion.caloriesPer100g.rounded()))
        if let proteinPer100g = suggestion.proteinPer100g {
            protein = String(format: "%.1f", proteinPer100g)
        }
        if let fatPer100g = suggestion.fatPer100g {
            fat = String(format: "%.1f", fatPer100g)
        }
        if let fiberPer100g = suggestion.fiberPer100g {
            fiber = String(format: "%.1f", fiberPer100g)
        }
        suggestionNotes = suggestion.notes
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
