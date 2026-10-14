import XCTest
@testable import CatIos

final class PricingTests: XCTestCase {
    func testPlusCostsLessThanTheMainCompetitors() {
        XCTAssertLessThan(PlanPricing.plusMonthly, PlanPricing.elevenPetsMonthly)
        XCTAssertLessThan(PlanPricing.plusMonthly, PlanPricing.petioMonthly)
        XCTAssertLessThan(PlanPricing.plusYearly, PlanPricing.petioYearly)
        XCTAssertLessThan(PlanPricing.yearlyPerMonth, PlanPricing.plusMonthly)
    }

    func testOnlyBasicIncludesAds() {
        XCTAssertTrue(AppPlan.basic.includesAds)
        XCTAssertFalse(AppPlan.plusMonthly.includesAds)
        XCTAssertFalse(AppPlan.plusYearly.includesAds)
    }

    @MainActor
    func testPlanStaysBasicUntilTheServerVerifiesIt() {
        UserDefaults.standard.removeObject(forKey: "patios.plan")
        let store = MembershipStore.shared
        store.applyServerPlan(nil)
        XCTAssertEqual(store.plan, .basic)
        XCTAssertTrue(store.plan.includesAds)
        XCTAssertNil(UserDefaults.standard.string(forKey: "patios.plan"))

        store.applyServerPlan("plus_yearly")
        XCTAssertEqual(store.plan, .plusYearly)
        XCTAssertFalse(store.plan.includesAds)
        XCTAssertNil(UserDefaults.standard.string(forKey: "patios.plan"))

        store.applyServerPlan("basic")
        XCTAssertEqual(store.plan, .basic)
    }
}
