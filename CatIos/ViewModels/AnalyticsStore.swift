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
        let cacheKey = "cache.\(path)"
        do {
            let fresh: APIAnalyticsReport = try await APIClient.shared.send("GET", path: path)
            report = fresh
            message = nil
            if let data = try? JSONEncoder().encode(fresh), let text = String(data: data, encoding: .utf8) {
                AppDatabase.shared.setValue(text, for: cacheKey)
            }
        } catch {
            // Offline: fall back to the last report saved on this device.
            if let text = AppDatabase.shared.value(for: cacheKey),
               let cached = try? JSONDecoder().decode(APIAnalyticsReport.self, from: Data(text.utf8)) {
                report = cached
                message = "Showing the last saved report — offline"
            } else {
                message = error.localizedDescription
            }
        }
    }
}
