import XCTest
@testable import LeapCore

final class ScrollEvidenceTests:XCTestCase {
    func nodes(_ y:Double)->[[String:Any]] {
        [["id":"a","frame":[10.0,y,20.0,20.0],"ancestors":["list"]],
         ["id":"b","frame":[10.0,y+30,20.0,20.0],"ancestors":["list"]]]
    }
    func testScopedTranslationAndUnchangedContent() {
        let before=nodes(100),after=nodes(70)
        XCTAssertEqual(ScrollEvidence.geometry(before:before,after:after,region:nil,root:"list",direction:"down")["status"] as? String,"movement_observed")
        XCTAssertEqual(ScrollEvidence.geometry(before:before,after:before,region:nil,root:"list",direction:"down")["status"] as? String,"unverified")
        XCTAssertEqual(ScrollEvidence.geometry(before:before,after:after,region:nil,root:nil,direction:"down")["status"] as? String,"unverified")
        XCTAssertEqual(ScrollEvidence.geometry(before:before,after:after,region:nil,root:"other",direction:"down")["status"] as? String,"unverified")
        XCTAssertEqual(ScrollEvidence.geometry(before:before,after:after,region:nil,root:"list",direction:"up")["status"] as? String,"unverified")
    }
    func testRetainedScreenshotsSeparateVisualDifferenceFromMovement() throws {
        let root=URL(fileURLWithPath:#filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        let dir=root.appendingPathComponent("artifacts/test-runs/20260920-ipad-pointer-native")
        let before:[String:Any]=["file":dir.appendingPathComponent("baseline.png").path]
        let after:[String:Any]=["file":dir.appendingPathComponent("sidebar-scrolled.png").path]
        XCTAssertEqual(try ScrollEvidence.pixels(before:before,after:before,region:[25,150,220,540],bounds:[130,99,1006,780])["status"] as? String,"no_visual_change_observed")
        XCTAssertEqual(try ScrollEvidence.pixels(before:before,after:after,region:[25,150,220,540],bounds:[130,99,1006,780])["status"] as? String,"visual_change_observed")
    }
    func testFullPageScrollWithNoSharedVisibleCenters() {
        XCTAssertEqual(ScrollEvidence.geometry(before:nodes(100),after:nodes(-360),region:[0,90,100,100],root:"list",direction:"down")["status"] as? String,"movement_observed")
    }
    func testScopedScrollbarValueWithoutChildMovement() {
        let a:[String:Any]=["id":"bar","role":"AXScrollBar","ancestors":["list"],"frame":[90,0,10,200],"value":"0"]
        var b=a;b["value"]="0.49"
        XCTAssertEqual(ScrollEvidence.geometry(before:[a],after:[b],region:nil,root:"list",direction:"down")["status"] as? String,"movement_observed")
        XCTAssertEqual(ScrollEvidence.geometry(before:[a],after:[b],region:nil,root:"other",direction:"down")["status"] as? String,"unverified")
        XCTAssertEqual(ScrollEvidence.geometry(before:[a],after:[b],region:nil,root:"list",direction:"up")["status"] as? String,"unverified")
    }
    func testRegionExcludesUnrelatedMovementAndValidatesBounds() {
        XCTAssertEqual(ScrollEvidence.geometry(before:nodes(100),after:nodes(70),region:[300,0,100,400],root:nil,direction:"down")["status"] as? String,"unverified")
        XCTAssertNotNil(ScrollEvidence.region([0,0,100,400],bounds:[130,99,1006,780]))
        XCTAssertNil(ScrollEvidence.region([950,0,100,400],bounds:[130,99,1006,780]))
        XCTAssertNil(ScrollEvidence.region([-1,0,100,400],bounds:[130,99,1006,780]))
    }
}
