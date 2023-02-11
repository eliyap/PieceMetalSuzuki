import XCTest
@testable import PieceMetalSuzuki

final class PieceMetalSuzukiTests: XCTestCase {
    
    func url(_ name: String) -> URL {
        Bundle.module.url(forResource: name, withExtension: ".png", subdirectory: "Images")!
    }
    
    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        PieceMetalSuzuki(imageUrl: url("waffle"))
//        PieceMetalSuzuki(imageUrl: url("input"))
        
    }
    
    func testWaffle() throws {
        _ = PieceMetalSuzuki(imageUrl: url("waffle"))
    }
    
    func testWhite() throws {
        _ = PieceMetalSuzuki(imageUrl: url("white"))
    }
}
