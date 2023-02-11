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
    }
    
    func testDoubleDonut() throws {
        _ = PieceMetalSuzuki(imageUrl: url("input"))
    }
    
    func testWaffle() throws {
        _ = PieceMetalSuzuki(imageUrl: url("waffle"))
    }
    
    func testWhite() throws {
        _ = PieceMetalSuzuki(imageUrl: url("white"))
    }
    
    func testDots() throws {
        _ = PieceMetalSuzuki(imageUrl: url("dots"))
    }
    
    func testDiamonds() throws {
        _ = PieceMetalSuzuki(imageUrl: url("diamonds"))
    }
    
    func testSquare() throws {
        _ = PieceMetalSuzuki(imageUrl: url("square"))
    }
}
