import Foundation
import Combine

@MainActor
final class WellnessStore: ObservableObject {
    static let shared = WellnessStore()

    @Published var foods: [FoodItem] { didSet { persistFoods() } }
    @Published var feedings: [FeedingEntry] { didSet { persistFeedings() } }
    @Published var weights: [WeightEntry] { didSet { persistWeights() } }
    @Published var behaviors: [BehaviorEntry] { didSet { persistBehaviors() } }

    private let database: AppDatabase
    private var ready = false

    init(database: AppDatabase = .shared) {
        self.database = database
        foods = database.loadFoods()
        feedings = database.loadFeedings()
        weights = database.loadWeights()
        behaviors = database.loadBehaviors()
        ready = true
    }

    func replaceFromRemote(foods: [FoodItem], feedings: [FeedingEntry], weights: [WeightEntry], behaviors: [BehaviorEntry]) {
        self.foods = foods
        self.feedings = feedings
        self.weights = weights
        self.behaviors = behaviors
    }

    func foods(matching query: String, favoritesOnly: Bool) -> [FoodItem] {
        let needle = query.trimmingCharacters(in: .whitespacesAndNewlines)
        return foods.filter { food in
            let favoriteMatches = !favoritesOnly || food.isFavorite
            let textMatches = needle.isEmpty
                || food.name.localizedCaseInsensitiveContains(needle)
                || food.brand.localizedCaseInsensitiveContains(needle)
                || food.productName.localizedCaseInsensitiveContains(needle)
            return favoriteMatches && textMatches
        }
    }

    private func persistFoods() { guard ready else { return }; database.saveFoods(foods); notify() }
    private func persistFeedings() { guard ready else { return }; database.saveFeedings(feedings); notify() }
    private func persistWeights() { guard ready else { return }; database.saveWeights(weights); notify() }
    private func persistBehaviors() { guard ready else { return }; database.saveBehaviors(behaviors); notify() }

    private func notify() {
        NotificationCenter.default.post(name: .householdDidChange, object: nil)
    }
}
