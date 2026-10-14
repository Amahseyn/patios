import XCTest
@testable import CatIos

final class ActivityInsightTests: XCTestCase {
    func testWalkingFilterIgnoresOtherActivities() {
        let now = Date()
        let walk = entry(.walk, minutes: 20, ago: 3_600, mood: "Bright", location: "River path", now: now)
        let play = entry(.play, minutes: 10, ago: 7_200, mood: "", location: "", now: now)
        let walking = CareAnalytics.activityFocus(
            entries: [walk, play],
            kind: .walk,
            days: 7,
            petName: "Luna",
            now: now
        )

        XCTAssertEqual(walking.sessions, 1)
        XCTAssertEqual(walking.minutes, 20)
        XCTAssertEqual(walking.averageMinutes, 20)
        XCTAssertEqual(walking.counts.map(\.0), [.walk])
        XCTAssertEqual(walking.moods.first?.0, "Bright")
        XCTAssertEqual(walking.places.first?.0, "River path")
        XCTAssertTrue(walking.notes[0].contains("Luna"))
        XCTAssertTrue(walking.notes[0].contains("walk"))
        XCTAssertFalse(walking.notes.joined().contains("play"))

        let playing = CareAnalytics.activityFocus(
            entries: [walk],
            kind: .play,
            days: 7,
            petName: "Luna",
            now: now
        )
        XCTAssertEqual(playing.sessions, 0)
        XCTAssertTrue(playing.notes[0].localizedCaseInsensitiveContains("play"))
    }

    func testAllActivitiesSummarizesTheLeadingKinds() {
        let now = Date()
        let entries = [
            entry(.walk, minutes: 15, ago: 1_000, mood: "", location: "", now: now),
            entry(.walk, minutes: 25, ago: 2_000, mood: "", location: "", now: now),
            entry(.training, minutes: 10, ago: 3_000, mood: "", location: "", now: now)
        ]
        let focus = CareAnalytics.activityFocus(entries: entries, kind: nil, days: 7, petName: "Your pets", now: now)
        XCTAssertEqual(focus.sessions, 3)
        XCTAssertEqual(focus.minutes, 50)
        XCTAssertEqual(focus.counts.map(\.0), [.walk, .training])
        XCTAssertTrue(focus.notes[1].contains("Walk 2"))
        XCTAssertTrue(focus.notes[1].contains("Training 1"))
        XCTAssertTrue(focus.notes[0].contains("50 minutes"))
    }

    func testDurationCaloriesAndFoodsUseCompatibleUnits() {
        XCTAssertEqual(MeasureText.duration(minutes: 20), "20 minutes")
        XCTAssertEqual(MeasureText.duration(minutes: 60), "1 hour")
        XCTAssertEqual(MeasureText.duration(minutes: 90), "1 hour 30 minutes")
        XCTAssertEqual(MeasureText.calories(144.4), "144 kcal")
        XCTAssertEqual(MeasureText.mass(grams: 40), "40 g")
        XCTAssertEqual(MeasureText.mass(grams: 1500), "1.5 kg")

        let now = Date()
        let longWalk = entry(.walk, minutes: 90, ago: 1_000, mood: "", location: "", now: now)
        let focus = CareAnalytics.activityFocus(entries: [longWalk], kind: .walk, days: 7, petName: "Luna", now: now)
        XCTAssertEqual(focus.minutes, 90)
        XCTAssertTrue(focus.notes[0].contains("1 hour 30 minutes"))

        let meal = FeedingEntry(
            petId: UUID(),
            fedAt: now,
            foodName: "Indoor kibble",
            amountGrams: 1500,
            calories: 144
        )
        let foods = CareAnalytics.foodShares([meal])
        XCTAssertEqual(foods.first?.name, "Indoor kibble")
        XCTAssertEqual(foods.first?.meals, 1)
        XCTAssertEqual(foods.first?.grams, 1500)
        XCTAssertEqual(foods.first?.calories, 144)
    }

    private func entry(
        _ kind: BehaviorKind,
        minutes: Int,
        ago: TimeInterval,
        mood: String,
        location: String,
        now: Date
    ) -> BehaviorEntry {
        BehaviorEntry(
            petId: UUID(),
            kind: kind,
            title: kind.rawValue,
            occurredAt: now.addingTimeInterval(-ago),
            durationMinutes: minutes,
            mood: mood,
            location: location,
            icon: kind.symbol,
            colorHex: kind.colorHex
        )
    }
}
