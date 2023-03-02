import XCTest
@testable import PieceMetalSuzuki

final class SmallPatternTests: XCTestCase {
    
    func url(_ name: String) -> URL {
        Bundle.module.url(forResource: name, withExtension: ".png", subdirectory: "Images")!
    }
    
    func checkPatternCountNoLUT(name: String, expectedCount: Int) throws {
        _ = PieceMetalSuzuki(imageUrl: url(name), patternSize: .w1h1, format: kCVPixelFormatType_32BGRA) { device, queue, texture, pixelBuffer, pointsFilled, runsFilled, pointsUnfilled, runsUnfilled in
            let ranges = applyMetalSuzuki(device: device, commandQueue: queue, texture: texture, pointsFilled: pointsFilled, runsFilled: runsFilled, pointsUnfilled: pointsUnfilled, runsUnfilled: runsUnfilled)
            XCTAssertNotNil(ranges)
            XCTAssertEqual(ranges!.count, expectedCount)
        }
    }
    
    func checkPatternCountLUT(name: String, expectedCount: Int, patternSize: PatternSize) throws {
        assert(loadLookupTablesJSON(patternSize))
        _ = PieceMetalSuzuki(imageUrl: url(name), patternSize: patternSize, format: kCVPixelFormatType_32BGRA) { device, queue, texture, pixelBuffer, pointsFilled, runsFilled, pointsUnfilled, runsUnfilled in
            let ranges = applyMetalSuzuki_LUT(device: device, commandQueue: queue, texture: texture, pointsFilled: pointsFilled, runsFilled: runsFilled, pointsUnfilled: pointsUnfilled, runsUnfilled: runsUnfilled, patternSize: patternSize)
            XCTAssertNotNil(ranges)
            XCTAssertEqual(ranges!.count, expectedCount)
        }
    }
    
    func testWaffle() throws {
        try checkPatternCountNoLUT(name: "waffle", expectedCount: 5)
        try checkPatternCountLUT(name: "waffle", expectedCount: 5, patternSize: .w2h2)
    }
    
    func testWhite() throws {
        try checkPatternCountNoLUT(name: "white", expectedCount: 1)
        try checkPatternCountLUT(name: "white", expectedCount: 1, patternSize: .w2h2)
    }
    
    func testDots() throws {
        try checkPatternCountNoLUT(name: "dots", expectedCount: 0)
        try checkPatternCountLUT(name: "dots", expectedCount: 0, patternSize: .w2h2)
    }
    
    func testDiamonds() throws {
        try checkPatternCountNoLUT(name: "diamonds", expectedCount: 5)
        try checkPatternCountLUT(name: "diamonds", expectedCount: 5, patternSize: .w2h2)
    }
    
    func testSquare() throws {
        try checkPatternCountNoLUT(name: "square", expectedCount: 2)
        try checkPatternCountLUT(name: "square", expectedCount: 2, patternSize: .w2h2)
    }
    
    func testDonut() throws {
        try checkPatternCountNoLUT(name: "donut", expectedCount: 4)
        try checkPatternCountLUT(name: "donut", expectedCount: 4, patternSize: .w2h2)
    }
}
