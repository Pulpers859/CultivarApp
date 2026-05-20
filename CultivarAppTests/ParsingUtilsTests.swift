import XCTest

#if canImport(Cultivar)
@testable import Cultivar
#elseif canImport(CultivarApp)
@testable import CultivarApp
#endif

final class ParsingUtilsTests: XCTestCase {
    func testParseLocalizedDecimalReturnsNilForBlankString() {
        XCTAssertNil(ParsingUtils.parseLocalizedDecimal(""))
        XCTAssertNil(ParsingUtils.parseLocalizedDecimal("   \n\t "))
    }

    func testParseLocalizedDecimalParsesSimpleDecimal() {
        let first = ParsingUtils.parseLocalizedDecimal("22.5")
        let second = ParsingUtils.parseLocalizedDecimal(" 60 ")
        XCTAssertNotNil(first)
        XCTAssertNotNil(second)
        XCTAssertEqual(first ?? 0, 22.5, accuracy: 0.0001)
        XCTAssertEqual(second ?? 0, 60, accuracy: 0.0001)
    }

    func testParseLocalizedDecimalParsesGroupedDecimal() {
        let result = ParsingUtils.parseLocalizedDecimal("1,200.75")
        XCTAssertNotNil(result)
        XCTAssertEqual(result ?? 0, 1200.75, accuracy: 0.0001)
    }
}
