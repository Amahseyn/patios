import Foundation
import Combine

@MainActor
final class AnalyticsStore: ObservableObject {
    static let shared = AnalyticsStore()

    @Published var report: APIAnalyticsReport?
    @Published var isLoading = false
    @Published var message: String?

    func load(petId: UUID) async {
        guard AuthSession.shared.isSignedIn else {
            report = nil
            message = "Sign in to load analytics from your account."
            return
        }
        isLoading = true
        defer { isLoading = false }
        let path = petId == PetManager.allPetsId ? "analytics" : "analytics/pets/\(petId.uuidString)"
        do {
            report = try await APIClient.shared.send("GET", path: path)
            message = nil
        } catch {
            message = error.localizedDescription
        }
    }
}
