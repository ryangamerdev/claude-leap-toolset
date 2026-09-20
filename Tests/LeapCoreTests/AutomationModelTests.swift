import XCTest
@testable import LeapCore

final class AutomationModelTests:XCTestCase {
    func testWDAOrientationProtocolTranslation() throws {
        XCTAssertEqual(try WDAClient.orientationValue("LANDSCAPE_RIGHT"),"UIA_DEVICE_ORIENTATION_LANDSCAPERIGHT")
        XCTAssertEqual(try WDAClient.orientationValue("PORTRAIT_UPSIDEDOWN"),"UIA_DEVICE_ORIENTATION_PORTRAIT_UPSIDEDOWN")
        XCTAssertEqual(try WDAClient.orientationValue("LANDSCAPE"),"LANDSCAPE")
        XCTAssertThrowsError(try WDAClient.orientationValue("unknown"))
    }
    func testOppositeLandscapeAndUnstableReadRejectCoordinates() {
        let before:[String:Any] = ["backend":"wda","orientation":"LANDSCAPE","orientationIdentity":"interface:0,0,90;device:left","orientationStable":true]
        var after=before
        XCTAssertTrue(AutomationModel.sameOrientation(before,after))
        after["orientationIdentity"]="interface:0,0,270;device:right"
        XCTAssertFalse(AutomationModel.sameOrientation(before,after))
        after=before;after["orientationStable"]=false
        XCTAssertFalse(AutomationModel.sameOrientation(before,after))
        after=before;after.removeValue(forKey:"orientationIdentity")
        XCTAssertFalse(AutomationModel.sameOrientation(before,after))
        XCTAssertTrue(AutomationModel.sameOrientation(["backend":"mac_ax"],["backend":"mac_ax"]))
    }
    func testMacCGFloatBoundsNormalizeLikeStoredJSON() throws {
        let live:[CGFloat]=[130,99,1006,780]
        XCTAssertEqual(AutomationModel.coordinateBounds(live),[130,99,1006,780])
        let stored=try JSONSerialization.jsonObject(with:JSONSerialization.data(withJSONObject:live))
        XCTAssertEqual(AutomationModel.coordinateBounds(live),AutomationModel.coordinateBounds(stored))
        XCTAssertNil(AutomationModel.coordinateBounds([true,0,1006,780] as [Any]))
        XCTAssertNil(AutomationModel.coordinateBounds([0,0,0,780]))
        XCTAssertNil(AutomationModel.coordinateBounds([0,0,1006,Double.infinity]))
    }
    func testBoundsSurviveJSONRoundTrip() throws {
        let live:[Double]=[0,0,1180,820]
        let stored=try JSONSerialization.jsonObject(with:JSONSerialization.data(withJSONObject:live))
        XCTAssertTrue(AutomationModel.sameBounds(live,stored))
        XCTAssertFalse(AutomationModel.sameBounds(live,[0,0,820,1180]))
        XCTAssertFalse(AutomationModel.sameBounds(live,[0,0,1180]))
        XCTAssertFalse(AutomationModel.sameBounds(live,[0,0,Double.nan,820]))
    }
    func testPartialAcquisitionCannotProveAbsenceOrUniqueState() {
        let node:[String:Any] = ["label":"Save","enabled":true]
        for condition in ["absent","count","enabled","exists"] {
            XCTAssertEqual(AutomationModel.verdict(nodes:[node],complete:false,expectation:["selector":["label":"Save"],"condition":condition,"value":1]),"unknown")
        }
    }
    func testDuplicatesAreUnknownForStateChecks() {
        let node:[String:Any] = ["label":"Save","enabled":true]
        XCTAssertEqual(AutomationModel.verdict(nodes:[node,node],complete:true,expectation:["selector":["label":"Save"],"condition":"enabled"]),"unknown")
        XCTAssertEqual(AutomationModel.verdict(nodes:[node,node],complete:true,expectation:["selector":["label":"Save"],"condition":"count","value":2]),"passed")
    }
    func testTruncatedValueCannotEstablishEquality() {
        XCTAssertEqual(AutomationModel.verdict(nodes:[["label":"Notes","value":"x","valueLimited":true]],complete:true,expectation:["selector":["label":"Notes"],"condition":"value_equals","value":"x"]),"unknown")
    }
    func testSelectorScopeAndExactMatching() throws {
        let node:[String:Any] = ["id":"child","label":"Save as","role":"AXButton","ancestors":["root"]]
        XCTAssertFalse(AutomationModel.matches(node,["label":"Save"]))
        XCTAssertTrue(AutomationModel.matches(node,["contains":"Save","role":"button","root":"root"]))
        XCTAssertThrowsError(try AutomationModel.validateSelector(["lable":"Save"]))
    }
    func testIncompleteDeltaDoesNotClaimRemoval() {
        let d=AutomationModel.delta([["id":"a"]],[],complete:false)
        XCTAssertEqual((d["changes"] as? [[String:Any]])?.first?["change"] as? String,"not_observed")
    }
    func testWholeResponseBudgetRetainsReference() throws {
        let result=try AutomationModel.bounded(["session_id":"s","steps":String(repeating:"x",count:30000)],budget:2048,file:"/repo/.leap/result.json")
        XCTAssertLessThan(result.utf8.count,2048)
        let decoded=try JSONSerialization.jsonObject(with:Data(result.utf8)) as? [String:Any]
        XCTAssertEqual(decoded?["file"] as? String,"/repo/.leap/result.json")
    }
    func testWDARejectsNonlocalAndCredentialEndpoints() {
        for endpoint in ["https://example.com:8100","http://user:pass@127.0.0.1:8100","http://localhost","http://localhost:8100/path"] {
            XCTAssertThrowsError(try WDAClient(endpoint:endpoint))
        }
    }
}
