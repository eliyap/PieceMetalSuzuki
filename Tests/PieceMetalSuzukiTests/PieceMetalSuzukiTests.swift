import XCTest
@testable import PieceMetalSuzuki

final class PieceMetalSuzukiTests: XCTestCase {
    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        PieceMetalSuzuki(imageUrl: Bundle.module.url(forResource: "input", withExtension: ".png")!)
    }
}
