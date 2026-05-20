import XCTest

#if canImport(Cultivar)
@testable import Cultivar
#elseif canImport(CultivarApp)
@testable import CultivarApp
#endif

final class SupportingModelsLogicTests: XCTestCase {
    func testPropagationRecordFlags() {
        let record = PropagationRecord(method: .stemCutting, numberOfCuttings: 2)
        XCTAssertFalse(record.isRooted)
        XCTAssertFalse(record.isPotted)

        record.rootedDate = Date()
        record.pottedDate = Date()
        XCTAssertTrue(record.isRooted)
        XCTAssertTrue(record.isPotted)
    }

    func testPropagationDaysInProgressUsesRootedDateWhenPresent() {
        let record = PropagationRecord(method: .division)
        let now = Date()
        record.dateStarted = Calendar.current.date(byAdding: .day, value: -5, to: now) ?? now
        record.rootedDate = now

        XCTAssertGreaterThanOrEqual(record.daysInProgress, 4)
        XCTAssertLessThanOrEqual(record.daysInProgress, 6)
    }

    func testEnvironmentTemperatureFahrenheitConversion() {
        let reading = EnvironmentReading(roomName: "Office", temperatureCelsius: 25)
        guard let fahrenheit = reading.temperatureFahrenheit else {
            return XCTFail("Expected fahrenheit conversion to be present")
        }
        XCTAssertEqual(fahrenheit, 77, accuracy: 0.0001)
    }
}
