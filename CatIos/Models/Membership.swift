import Foundation
import Combine
import StoreKit

enum AppPlan: String, CaseIterable, Identifiable {
    case basic
    case plusMonthly
    case plusYearly

    var id: String { rawValue }

    var includesAds: Bool { self == .basic }

    var title: String {
        switch self {
        case .basic: return "Basic"
        case .plusMonthly: return "Pet Care+ Monthly"
        case .plusYearly: return "Pet Care+ Yearly"
        }
    }

    var priceLabel: String {
        switch self {
        case .basic: return "Free"
        case .plusMonthly: return "\(PlanPricing.usd(PlanPricing.plusMonthly)) / month"
        case .plusYearly: return "\(PlanPricing.usd(PlanPricing.plusYearly)) / year"
        }
    }

    var detail: String {
        switch self {
        case .basic:
            return "Pets, tasks, health, and the assistant. Ads stay on the main screens."
        case .plusMonthly:
            return "Same care tools, without ads. Less than 11pets at about \(PlanPricing.usd(PlanPricing.elevenPetsMonthly)) a month."
        case .plusYearly:
            return "\(PlanPricing.usd(PlanPricing.yearlyPerMonth)) a month, billed once a year. Less than Petio Plus at \(PlanPricing.usd(PlanPricing.petioYearly)) a year."
        }
    }
}

enum PlanPricing {
    static let plusMonthly = Decimal(string: "3.99")!
    static let plusYearly = Decimal(string: "29.99")!
    static let elevenPetsMonthly = Decimal(string: "4.99")!
    static let petioMonthly = Decimal(string: "5.99")!
    static let petioYearly = Decimal(string: "47.99")!

    static var yearlyPerMonth: Decimal { plusYearly / 12 }

    static func usd(_ value: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter.string(from: value as NSDecimalNumber) ?? "$\(value)"
    }
}

struct HouseAd: Identifiable, Equatable {
    let id: Int
    let title: String
    let detail: String

    static let catalog: [HouseAd] = [
        HouseAd(id: 0, title: "A little checkup", detail: "A sponsored reminder to book the next visit for whoever you love."),
        HouseAd(id: 1, title: "Fresh meals this week", detail: "A sponsored note about stocking the bowls, dishes, and hay."),
        HouseAd(id: 2, title: "A softer evening", detail: "A sponsored wish: one last bit of play before the house grows quiet."),
    ]

    static var today: HouseAd {
        let day = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 0
        return catalog[day % catalog.count]
    }
}

enum StoreCatalog {
    static let monthly = "petcare.plus.monthly"
    static let yearly = "petcare.plus.yearly"
    static let ids = [monthly, yearly]
}

@MainActor
final class MembershipStore: ObservableObject {
    static let shared = MembershipStore()

    @Published private(set) var plan: AppPlan = .basic
    @Published private(set) var products: [Product] = []
    @Published private(set) var purchasesUnavailable = false
    @Published var statusMessage: String?

    func applyServerPlan(_ raw: String?) {
        switch raw {
        case "plus_monthly": plan = .plusMonthly
        case "plus_yearly": plan = .plusYearly
        default: plan = .basic
        }
    }

    func loadProducts() async {
        do {
            let loaded = try await Product.products(for: StoreCatalog.ids)
            products = loaded.sorted { $0.id == StoreCatalog.yearly && $1.id != StoreCatalog.yearly }
            purchasesUnavailable = loaded.isEmpty
            if loaded.isEmpty {
                statusMessage = "Purchases are unavailable right now. Pet Care stays on Basic."
            }
        } catch {
            products = []
            purchasesUnavailable = true
            statusMessage = "Purchases are unavailable right now. Pet Care stays on Basic."
        }
    }

    func product(for plan: AppPlan) -> Product? {
        switch plan {
        case .plusMonthly: return products.first { $0.id == StoreCatalog.monthly }
        case .plusYearly: return products.first { $0.id == StoreCatalog.yearly }
        case .basic: return nil
        }
    }

    func purchase(_ plan: AppPlan) async -> Bool {
        guard plan != .basic else { return true }
        guard AuthSession.shared.isSignedIn else {
            statusMessage = "Sign in from Settings so this purchase can be saved to your account."
            return false
        }
        guard let product = product(for: plan) else {
            purchasesUnavailable = true
            statusMessage = "Purchases are unavailable right now. Pet Care stays on Basic."
            return false
        }
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try verified(verification)
                let saved = try await submit(verification.jwsRepresentation)
                await transaction.finish()
                statusMessage = nil
                return saved
            case .userCancelled, .pending:
                return false
            @unknown default:
                return false
            }
        } catch {
            statusMessage = error.localizedDescription
            return false
        }
    }

    func restore() async {
        guard AuthSession.shared.isSignedIn else {
            statusMessage = "Sign in from Settings so a restored purchase can be saved to your account."
            return
        }
        do {
            try await AppStore.sync()
            var restored = false
            for await result in Transaction.currentEntitlements {
                let transaction = try verified(result)
                guard StoreCatalog.ids.contains(transaction.productID) else { continue }
                if try await submit(result.jwsRepresentation) {
                    restored = true
                }
            }
            if !restored {
                applyServerPlan("basic")
                statusMessage = "No active Pet Care+ purchase was found. Pet Care stays on Basic."
            } else {
                statusMessage = nil
            }
        } catch {
            statusMessage = error.localizedDescription
        }
    }

    private func submit(_ signedTransaction: String) async throws -> Bool {
        struct Body: Encodable { let signedTransaction: String }
        let user: APIUser = try await APIClient.shared.send("POST", path: "billing/apple", body: Body(signedTransaction: signedTransaction))
        AuthSession.shared.adopt(user)
        return plan != .basic
    }

    private func verified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw APIError.message("The App Store could not verify this purchase.")
        case .verified(let safe):
            return safe
        }
    }
}
