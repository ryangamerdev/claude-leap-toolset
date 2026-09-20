import XCTest
@testable import LeapCore

final class DiagnosticsTests:XCTestCase {
    func directory() -> String {
        URL(fileURLWithPath:#filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().appendingPathComponent("artifacts/test-runs/20260920-diagnostics/fixtures/\(UUID().uuidString)").path
    }
    func testDurabilityFiltersAndLateWarning() throws {
        let path=directory()
        do {
            let d=Diagnostics(directory:path);d.setContext(["interaction":"i1","tool":"click","app":"Simulator"])
            for _ in 0..<25 {XCTAssertNotNil(d.record(level:"info",kind:"attempt",detail:"ack is not success"))}
            XCTAssertNotNil(d.record(level:"warning",kind:"fallback",detail:"recovery needed",fields:["session":"s1"]))
            XCTAssertTrue(d.warningSummary(interaction:"i1")?.contains("fallback") == true)
        }
        let d=Diagnostics(directory:path)
        let raw=try d.query(interaction:"i1",session:"s1",level:"issues",kind:nil,after:0,limit:1)
        let obj=try JSONSerialization.jsonObject(with:Data(raw.utf8)) as! [String:Any]
        XCTAssertEqual((obj["items"] as? [[String:Any]])?.count,1)
        XCTAssertEqual(obj["hasMore"] as? Bool,false)
        XCTAssertEqual(obj["nextCursor"] as? Int,26)
        XCTAssertTrue(try d.query(interaction:"i1",session:nil,level:nil,kind:nil,after:0,limit:1).contains("\"hasMore\":true"))
    }
    func testConfigurationAndFilteredWarningsStayVisible() throws {
        let home=directory()
        try FileManager.default.createDirectory(atPath:home+"/.config/leap",withIntermediateDirectories:true)
        let config=URL(fileURLWithPath:home+"/.config/leap/leap.json")
        try Data("{\"logging\":{\"level\":\"error\"}}".utf8).write(to:config)
        let d=Diagnostics.configured(home:home)
        XCTAssertEqual(d.directory,home+"/.leap/logs")
        d.setContext(["interaction":"i"])
        XCTAssertNotNil(d.record(level:"warning",kind:"fallback",detail:"not silent"))
        XCTAssertTrue(d.warningSummary(interaction:"i")?.contains("not retained") == true)
        XCTAssertFalse(try d.query(interaction:"i",session:nil,level:nil,kind:nil,after:0,limit:20).contains("not silent"))
        try Data("{bad".utf8).write(to:config)
        let invalid=Diagnostics.configured(home:home)
        XCTAssertNotNil(invalid.health())
        XCTAssertNil(invalid.record(level:"info",kind:"attempt",detail:"must block"))
    }
    func testInsightsSwitchDefaultsAndValidation() throws {
        let home=directory()
        XCTAssertTrue(Diagnostics.configured(home:home).insightsEnabled)
        try FileManager.default.createDirectory(atPath:home+"/.config/leap",withIntermediateDirectories:true)
        let file=URL(fileURLWithPath:home+"/.config/leap/leap.json")
        try Data(#"{"insights":{"enabled":false},"logging":{"level":"warning"}}"#.utf8).write(to:file)
        let disabled=Diagnostics.configured(home:home)
        XCTAssertFalse(disabled.insightsEnabled)
        XCTAssertEqual(disabled.level,"warning")
        XCTAssertNil(disabled.health())
        try Data(#"{"insights":{"enabled":0}}"#.utf8).write(to:file)
        XCTAssertNotNil(Diagnostics.configured(home:home).health())
    }
    func testUnavailableStoreIsExplicit() throws {
        let path=directory();try FileManager.default.createDirectory(atPath:path,withIntermediateDirectories:true)
        let blocker=path+"/file";try Data("blocked".utf8).write(to:URL(fileURLWithPath:blocker))
        let d=Diagnostics(directory:blocker+"/logs")
        XCTAssertNil(d.record(level:"error",kind:"failure",detail:"example"))
        XCTAssertNotNil(d.health())
    }
}
