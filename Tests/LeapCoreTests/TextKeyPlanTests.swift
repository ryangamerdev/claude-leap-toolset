import XCTest
@testable import LeapCore

final class TextKeyPlanTests: XCTestCase {
    func testPhysicalCodesAndCaseArePreserved() throws {
        let map: [String: TextKeyPlan.Stroke] = ["b": .init(code: 11, flags: [], text: "b"), "B": .init(code: 11, flags: .maskShift, text: "B")]
        let plan = try TextKeyPlan.plan("bB\r\n\t", layout: map, requirePhysical: true)
        XCTAssertEqual(plan.map(\.code), [11,11,36,48])
        XCTAssertEqual(plan[1].flags, .maskShift)
    }
    func testUnsupportedSimulatorCharacterRejectsEntirePlan() {
        XCTAssertThrowsError(try TextKeyPlan.plan("b😀", layout: ["b": .init(code: 11, flags: [], text: "b")], requirePhysical: true))
    }
    func testUnicodeFallbackKeepsWholeCharacterForOtherApps() throws {
        let plan = try TextKeyPlan.plan("😀", layout: [:], requirePhysical: false)
        XCTAssertEqual(plan.count, 1)
        XCTAssertEqual(plan[0].text, "😀")
    }
    func testCurrentLayoutCanBeReadWithoutSendingInput() throws {
        XCTAssertFalse(try TextKeyPlan.layoutMap().isEmpty)
    }
}
