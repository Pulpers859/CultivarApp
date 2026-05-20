import XCTest

#if canImport(Cultivar)
@testable import Cultivar
#elseif canImport(CultivarApp)
@testable import CultivarApp
#endif

final class WateringScheduleTests: XCTestCase {
    func testNormalizedIntervalClampsAtLeastOneDay() {
        XCTAssertEqual(WateringSchedule.normalizedIntervalDays(7), 7)
        XCTAssertEqual(WateringSchedule.normalizedIntervalDays(1), 1)
        XCTAssertEqual(WateringSchedule.normalizedIntervalDays(0), 1)
        XCTAssertEqual(WateringSchedule.normalizedIntervalDays(-3), 1)
    }

    func testNextWateringDateUsesNowWhenNeverWatered() {
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let next = WateringSchedule.nextWateringDate(
            lastWatered: nil,
            intervalDays: 7,
            now: now
        )
        XCTAssertEqual(next, now)
    }

    func testDaysUntilWaterReturnsZeroWhenNeverWatered() {
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let days = WateringSchedule.daysUntilWater(
            lastWatered: nil,
            intervalDays: 7,
            now: now
        )
        XCTAssertEqual(days, 0)
    }

    func testDaysUntilWaterHandlesOverdueDates() {
        let calendar = Calendar(identifier: .gregorian)
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let lastWatered = calendar.date(byAdding: .day, value: -10, to: now)!

        let days = WateringSchedule.daysUntilWater(
            lastWatered: lastWatered,
            intervalDays: 7,
            now: now,
            calendar: calendar
        )

        XCTAssertNotNil(days)
        XCTAssertLessThan(days ?? 0, 0)
    }
}
