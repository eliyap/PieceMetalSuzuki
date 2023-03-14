import XCTest
@testable import PieceMetalSuzuki

final class SmallPatternTests: XCTestCase {
    
    let patternSize = PatternSize.w2h2
    
    func url(_ name: String) -> URL {
        Bundle.module.url(forResource: name, withExtension: ".png", subdirectory: "Images")!
    }
    
    func checkPatternCountNoLUT(name: String, expectedCount: Int) throws {
        _ = PieceMetalSuzuki(imageUrl: url(name), patternSize: .w1h1, format: kCVPixelFormatType_32BGRA) { device, queue, texture, pixelBuffer in
            let ranges = applyMetalSuzuki(device: device, commandQueue: queue, texture: texture)
            XCTAssertNotNil(ranges)
            XCTAssertEqual(ranges!.count, expectedCount)
        }
    }
    
    func checkPatternCountProtoBuf(name: String, expectedCount: Int, patternSize: PatternSize) throws {
        assert(loadLookupTablesProtoBuf(patternSize))
        _ = PieceMetalSuzuki(imageUrl: url(name), patternSize: patternSize, format: kCVPixelFormatType_32BGRA) { device, queue, texture, pixelBuffer in
            let borders = applyMetalSuzuki_LUT(device: device, commandQueue: queue, texture: texture, patternSize: patternSize)
            XCTAssertNotNil(borders)
            XCTAssertEqual(borders!.count, expectedCount)
        }
    }
    
    func checkPatternCountData(name: String, expectedCount: Int, patternSize: PatternSize) throws {
        assert(loadLookupTablesData(patternSize))
        _ = PieceMetalSuzuki(imageUrl: url(name), patternSize: patternSize, format: kCVPixelFormatType_32BGRA) { device, queue, texture, pixelBuffer in
            let borders = applyMetalSuzuki_LUT(device: device, commandQueue: queue, texture: texture, patternSize: patternSize)
            XCTAssertNotNil(borders)
            XCTAssertEqual(borders!.count, expectedCount)
        }
    }
    
    func testWaffle() throws {
        try checkPatternCountNoLUT(name: "waffle", expectedCount: 5)
        try checkPatternCountProtoBuf(name: "waffle", expectedCount: 5, patternSize: patternSize)
        try checkPatternCountData(name: "waffle", expectedCount: 5, patternSize: patternSize)
    }
    
    func testWhite() throws {
        try checkPatternCountNoLUT(name: "white", expectedCount: 1)
        try checkPatternCountProtoBuf(name: "white", expectedCount: 1, patternSize: patternSize)
        try checkPatternCountData(name: "white", expectedCount: 1, patternSize: patternSize)
    }
    
    func testDots() throws {
        try checkPatternCountNoLUT(name: "dots", expectedCount: 0)
        try checkPatternCountProtoBuf(name: "dots", expectedCount: 0, patternSize: patternSize)
        try checkPatternCountData(name: "dots", expectedCount: 0, patternSize: patternSize)
    }
    
    func testDiamonds() throws {
        try checkPatternCountNoLUT(name: "diamonds", expectedCount: 5)
        try checkPatternCountProtoBuf(name: "diamonds", expectedCount: 5, patternSize: patternSize)
        try checkPatternCountData(name: "diamonds", expectedCount: 5, patternSize: patternSize)
    }
    
    func testSquare() throws {
        try checkPatternCountNoLUT(name: "square", expectedCount: 2)
        try checkPatternCountProtoBuf(name: "square", expectedCount: 2, patternSize: patternSize)
        try checkPatternCountData(name: "square", expectedCount: 2, patternSize: patternSize)
    }
    
    func testDonut() throws {
        try checkPatternCountNoLUT(name: "donut", expectedCount: 4)
        try checkPatternCountProtoBuf(name: "donut", expectedCount: 4, patternSize: patternSize)
        try checkPatternCountData(name: "donut", expectedCount: 4, patternSize: patternSize)
    }
}
