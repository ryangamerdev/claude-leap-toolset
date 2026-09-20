import XCTest
import ApplicationServices
@testable import LeapCore

final class ObservationQualityTests: XCTestCase {
    func testOnlyKnownNonTextSubrolesAreAdvisory() {
        XCTAssertTrue(AX.advisoryFailure(attribute: "AXSubrole", role: "AXCheckBox"))
        for role in ["AXTextField", "AXSecureTextField", "AXUnknown", "AXGroup"] {
            XCTAssertFalse(AX.advisoryFailure(attribute: "AXSubrole", role: role))
        }
        XCTAssertFalse(AX.advisoryFailure(attribute: "AXSubrole", role: nil))
        for attribute in ["AXChildren", "AXRole", "AXValue", "AXEnabled", "AXTitle"] {
            XCTAssertFalse(AX.advisoryFailure(attribute: attribute, role: "AXButton"))
        }
    }
    func testErrorCountsStayCompleteWhenSamplesAreCapped() {
        let element = AXUIElementCreateApplication(0)
        AX.withBudget(1) {
            for _ in 0..<12 {
                AX.note(.failure, attribute: "AXSubrole", element: element, role: "AXCheckBox")
            }
            AX.note(.cannotComplete, attribute: "AXChildren", element: element, role: "AXGroup")
            AX.note(.cannotComplete, attribute: "AXSubrole", element: element, role: "AXCheckBox")
            AX.note(.attributeUnsupported, attribute: "AXSubrole", element: element)
            XCTAssertEqual(AX.budget?.failures, 14)
            XCTAssertEqual(AX.budget?.advisoryFailures, 12)
            XCTAssertEqual(AX.budget?.failureDetails.count, 8)
        }
    }
}
