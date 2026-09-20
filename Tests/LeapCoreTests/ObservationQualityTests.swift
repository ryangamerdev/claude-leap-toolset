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
    func testTextAreaMetadataIsAdvisoryButStateAndTransportRemainBlocking() {
        XCTAssertTrue(AX.advisoryFailure(attribute:"AXIdentifier",role:"AXTextArea"))
        XCTAssertTrue(AX.advisoryFailure(attribute:"AXDescription",role:"AXTextArea"))
        for a in ["AXValue","AXChildren","AXSubrole","AXEnabled"] {XCTAssertFalse(AX.advisoryFailure(attribute:a,role:"AXTextArea"))}
        AX.withBudget(1) {
            AX.note(.cannotComplete,attribute:"AXDescription",element:AXUIElementCreateApplication(0),role:"AXTextArea")
            XCTAssertEqual(AX.budget?.advisoryFailures,0)
        }
    }
    func testMissingMetadataCannotProveSelectorAbsenceOrUniqueness() {
        let nodes:[[String:Any]]=[
            ["id":"notes","role":"AXTextArea","label":"","value":"hello","unavailableFields":["label","identifier"]],
            ["id":"save","role":"AXButton","label":"Save"]]
        XCTAssertTrue(AutomationModel.selectionReliable(nodes,["role":"button","label":"Save"]))
        XCTAssertTrue(AutomationModel.selectionReliable(nodes,["id":"notes"]))
        XCTAssertFalse(AutomationModel.selectionReliable(nodes,["label":"Save"]))
        XCTAssertFalse(AutomationModel.selectionReliable(nodes,["identifier":"missing"]))
        XCTAssertEqual(AutomationModel.verdict(nodes:nodes,complete:true,expectation:["selector":["identifier":"missing"],"condition":"absent"]),"unknown")
        XCTAssertEqual(AutomationModel.verdict(nodes:nodes,complete:true,expectation:["selector":["id":"notes"],"condition":"value_equals","value":"hello"]),"passed")
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
