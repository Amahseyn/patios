import Foundation

struct FoodSuggestBody: Encodable {
    var query: String
    var brand: String = ""
    var petId: UUID?
    var species: String
    var breed: String = ""
    var ageYears: Int
    var weightKg: Double
    var activityLevel: String
    var mealsPerDay: Int
}

@MainActor
enum FoodSuggestionService {
    struct Context {
        var petId: UUID?
        var species: String
        var breed: String
        var ageYears: Int
        var weightKg: Double
        var activityLevel: String
        var mealsPerDay: Int
    }

    static func suggest(
        query: String,
        brand: String = "",
        context: Context,
        signedIn: Bool
    ) async -> APIFoodSuggest {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return localSuggest(query: "Meal", brand: brand, context: context)
        }

        if signedIn {
            let body = FoodSuggestBody(
                query: trimmed,
                brand: brand,
                petId: context.petId,
                species: context.species,
                breed: context.breed,
                ageYears: context.ageYears,
                weightKg: context.weightKg,
                activityLevel: context.activityLevel,
                mealsPerDay: context.mealsPerDay
            )
            if let remote: APIFoodSuggest = try? await APIClient.shared.send(
                "POST",
                path: "insights/food-suggest",
                body: body
            ) {
                return remote
            }
        }

        return localSuggest(query: trimmed, brand: brand, context: context)
    }

    static func localSuggest(query: String, brand: String, context: Context) -> APIFoodSuggest {
        let profile = localFoodProfile(for: query)
        let portion = CareInsights.portion(
            species: context.species,
            ageYears: context.ageYears,
            weightKg: context.weightKg,
            activity: context.activityLevel,
            meals: context.mealsPerDay,
            caloriesPer100g: profile.caloriesPer100g,
            proteinPer100g: profile.protein,
            fatPer100g: profile.fat,
            fiberPer100g: profile.fiber
        )
        let grams = portion.gramsPerServing ?? max(1, Int((Double(portion.caloriesPerMeal) / profile.caloriesPer100g * 100).rounded()))
        return APIFoodSuggest(
            disclaimer: CareInsights.disclaimer,
            source: "estimate",
            name: query,
            brand: brand,
            productName: "",
            category: profile.category,
            caloriesPer100g: profile.caloriesPer100g,
            proteinPer100g: profile.protein,
            fatPer100g: profile.fat,
            fiberPer100g: profile.fiber,
            suggestedGrams: grams,
            suggestedCalories: portion.caloriesPerMeal,
            notes: portion.notes
        )
    }

    private struct LocalFoodProfile {
        var category: String
        var caloriesPer100g: Double
        var protein: Double?
        var fat: Double?
        var fiber: Double?
    }

    private static func localFoodProfile(for query: String) -> LocalFoodProfile {
        let folded = query.lowercased()
        if folded.contains("treat") || folded.contains("snack") {
            return LocalFoodProfile(category: "Treats", caloriesPer100g: 350, protein: 12, fat: 18, fiber: 2)
        }
        if folded.contains("wet") || folded.contains("canned") || folded.contains("pouch") {
            return LocalFoodProfile(category: "Wet food", caloriesPer100g: 85, protein: 9, fat: 4, fiber: 1)
        }
        if folded.contains("chicken") {
            return LocalFoodProfile(category: "Homemade", caloriesPer100g: 165, protein: 31, fat: 3.6, fiber: 0)
        }
        if folded.contains("salmon") || folded.contains("fish") {
            return LocalFoodProfile(category: "Homemade", caloriesPer100g: 180, protein: 20, fat: 10, fiber: 0)
        }
        if folded.contains("rice") {
            return LocalFoodProfile(category: "Homemade", caloriesPer100g: 130, protein: 2.7, fat: 0.3, fiber: 0.4)
        }
        if folded.contains("kibble") || folded.contains("dry") {
            return LocalFoodProfile(category: "Dry food", caloriesPer100g: 360, protein: 30, fat: 14, fiber: 4)
        }
        return LocalFoodProfile(category: "Other", caloriesPer100g: 320, protein: 24, fat: 12, fiber: 3)
    }
}
