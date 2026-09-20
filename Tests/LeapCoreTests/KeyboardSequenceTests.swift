import XCTest
import CoreGraphics
@testable import LeapCore

final class KeyboardSequenceTests: XCTestCase {
    func testChordBracketsKeysAndRestoresPriorModifiers() throws {
        let events = try Input.keyboardSequence(code: 0, flags: .maskCommand, restoring: .maskShift)
        XCTAssertEqual(events.map(\.type), [.flagsChanged, .keyDown, .keyUp, .flagsChanged])
        XCTAssertEqual(events.map(\.flags), [.maskCommand, .maskCommand, .maskCommand, .maskShift])
        XCTAssertEqual(events[1].getIntegerValueField(.keyboardEventKeycode), 0)
        XCTAssertEqual(events[2].getIntegerValueField(.keyboardEventKeycode), 0)
    }
    func testUnicodeSurrogatePairsArePreservedOnBothEdges() throws {
        let text = Array("A😀".utf16)
        let events = try Input.keyboardSequence(code: 0, flags: [], unicode: text, restoring: [])
        for event in events[1...2] {
            var actual = 0
            var buffer = [UniChar](repeating: 0, count: 8)
            event.keyboardGetUnicodeString(maxStringLength: buffer.count, actualStringLength: &actual, unicodeString: &buffer)
            XCTAssertEqual(Array(buffer.prefix(actual)), text)
        }
    }
}
