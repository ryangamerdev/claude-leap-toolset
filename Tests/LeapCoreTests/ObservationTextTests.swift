import XCTest
@testable import LeapCore

final class ObservationTextTests: XCTestCase {
    func testCustomActionDescriptorsShowTheirName() {
        XCTAssertEqual(AX.actionName("Name:pin\nTarget:0x0\nSelector:(null)"), "pin")
        XCTAssertEqual(AX.actionName("AXPress"), "Press")
        XCTAssertEqual(AX.actionName("ICMacTextViewAccessibilityActionShowExtensionsMenu"), "ICMacTextViewAccessibilityActionShowExtensionsMenu")
    }
    func testDisabledRunsCollapseButLoneDisabledControlsStay() async {
        let engine = Engine()
        let inactive = (1...6).map { "  [\($0)] Button desc=\"Old \($0)\" [disabled]" }
        let text = (["[1] Button desc=\"Save\" [disabled]", "[2] Button desc=\"Cancel\""] + inactive + ["[9] Button desc=\"Next\""]).joined(separator: "\n")
        let out = await engine.compactObservation(text)
        XCTAssertTrue(out.contains("desc=\"Save\" [disabled]"))
        XCTAssertTrue(out.contains("6 disabled elements"))
        XCTAssertFalse(out.contains("Old 4"))
        XCTAssertTrue(out.contains("desc=\"Next\""))
    }
}
