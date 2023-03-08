import XCTest
@testable import PieceMetalSuzuki

final class SuzukiTimeProfile: XCTestCase {
    
    func url(_ name: String) -> URL {
        Bundle.module.url(forResource: name, withExtension: ".png", subdirectory: "Images")!
    }
    
    func testNoLUT() async throws {
        measure {
            _ = PieceMetalSuzuki(imageUrl: url("input"), patternSize: .w1h1, format: kCVPixelFormatType_32BGRA) { device, queue, texture, pixelBuffer, pointsFilled, runsFilled, pointsUnfilled, runsUnfilled in
                applyMetalSuzuki(device: device, commandQueue: queue, texture: texture, pointsFilled: pointsFilled, runsFilled: runsFilled, pointsUnfilled: pointsUnfilled, runsUnfilled: runsUnfilled)
            }
        }
        
        await SuzukiProfiler.report()
    }
    
    func timeLUT(patternSize: PatternSize) async throws {
        assert(loadLookupTablesData(patternSize))
        
        let options = SuzukiTimeProfile.defaultMeasureOptions
        options.iterationCount = 10
        measure(options: options) {
            _ = PieceMetalSuzuki(imageUrl: url("bigDots"), patternSize: patternSize, format: kCVPixelFormatType_32BGRA) { device, queue, texture, pixelBuffer, pointsFilled, runsFilled, pointsUnfilled, runsUnfilled in
                _ = applyMetalSuzuki_LUT(device: device, commandQueue: queue, texture: texture, pointsFilled: pointsFilled, runsFilled: runsFilled, pointsUnfilled: pointsUnfilled, runsUnfilled: runsUnfilled, patternSize: patternSize)
            }
        }
        
        await SuzukiProfiler.report()
    }
    
    func testLUT1x1() async throws {
        try await timeLUT(patternSize: .w1h1)
    }
    
    func testLUT2x1() async throws {
        try await timeLUT(patternSize: .w2h1)
    }
    
    func testLUT2x2() async throws {
        try await timeLUT(patternSize: .w2h2)
    }
}
