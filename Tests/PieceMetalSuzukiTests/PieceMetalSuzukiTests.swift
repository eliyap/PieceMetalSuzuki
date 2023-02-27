import XCTest
@testable import PieceMetalSuzuki

final class PieceMetalSuzukiTests: XCTestCase {
    
    func url(_ name: String) -> URL {
        Bundle.module.url(forResource: name, withExtension: ".png", subdirectory: "Images")!
    }
    
    @available(iOS 16.0, *)
    @available(macOS 13.0, *)
    func testEmitLUT2x1() async throws {
        LookupTableBuilder(patternSize: .w2h1).emit()
    }
    
    @available(iOS 16.0, *)
    @available(macOS 13.0, *)
    func testEmitLUT2x2() async throws {
        LookupTableBuilder(patternSize: .w2h2).emit()
    }
    
    func testRDP() throws {
        let patternSize = PatternSize.w2h2
        loadLookupTables(patternSize)
        
        let imageUrl = url("qrTilt")
        _ = PieceMetalSuzuki(imageUrl: imageUrl, patternSize: patternSize) { device, queue, texture, pixelBuffer, pointsFilled, runsFilled, pointsUnfilled, runsUnfilled in
            let runIndices = applyMetalSuzuki_LUT(device: device, commandQueue: queue, texture: texture, pointsFilled: pointsFilled, runsFilled: runsFilled, pointsUnfilled: pointsUnfilled, runsUnfilled: runsUnfilled, patternSize: patternSize)!
            decodeMarkers(pixelBuffer: pixelBuffer, pointBuffer: pointsFilled, runBuffer: runsFilled, runIndices: runIndices)
        }
    }
}
