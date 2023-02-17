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
    
    func testDoubleDonut() async throws {
        measure {
            _ = PieceMetalSuzuki(imageUrl: url("input"), coreSize: PixelSize(width: 1, height: 1), pointsPerPixel: 4) { device, queue, texture, pointsFilled, runsFilled, pointsUnfilled, runsUnfilled in
                applyMetalSuzuki(device: device, commandQueue: queue, texture: texture, pointsFilled: pointsFilled, runsFilled: runsFilled, pointsUnfilled: pointsUnfilled, runsUnfilled: runsUnfilled)
            }
        }
        
        await Profiler.report()
    }
    
    func testWaffle() throws {
        _ = PieceMetalSuzuki(imageUrl: url("waffle"), coreSize: PixelSize(width: 1, height: 1), pointsPerPixel: 4) { device, queue, texture, pointsFilled, runsFilled, pointsUnfilled, runsUnfilled in
            applyMetalSuzuki(device: device, commandQueue: queue, texture: texture, pointsFilled: pointsFilled, runsFilled: runsFilled, pointsUnfilled: pointsUnfilled, runsUnfilled: runsUnfilled)
        }
    }
    
    func testWhite() throws {
        _ = PieceMetalSuzuki(imageUrl: url("white"), coreSize: PixelSize(width: 1, height: 1), pointsPerPixel: 4) { device, queue, texture, pointsFilled, runsFilled, pointsUnfilled, runsUnfilled in
            applyMetalSuzuki(device: device, commandQueue: queue, texture: texture, pointsFilled: pointsFilled, runsFilled: runsFilled, pointsUnfilled: pointsUnfilled, runsUnfilled: runsUnfilled)
        }
    }
    
    func testDots() throws {
        _ = PieceMetalSuzuki(imageUrl: url("dots"), coreSize: PixelSize(width: 1, height: 1), pointsPerPixel: 4) { device, queue, texture, pointsFilled, runsFilled, pointsUnfilled, runsUnfilled in
            applyMetalSuzuki(device: device, commandQueue: queue, texture: texture, pointsFilled: pointsFilled, runsFilled: runsFilled, pointsUnfilled: pointsUnfilled, runsUnfilled: runsUnfilled)
        }
    }
    
    func testDiamonds() throws {
        _ = PieceMetalSuzuki(imageUrl: url("diamonds"), coreSize: PixelSize(width: 1, height: 1), pointsPerPixel: 4) { device, queue, texture, pointsFilled, runsFilled, pointsUnfilled, runsUnfilled in
            applyMetalSuzuki(device: device, commandQueue: queue, texture: texture, pointsFilled: pointsFilled, runsFilled: runsFilled, pointsUnfilled: pointsUnfilled, runsUnfilled: runsUnfilled)
        }
    }
    
    func testSquare() throws {
        _ = PieceMetalSuzuki(imageUrl: url("square"), coreSize: PixelSize(width: 1, height: 1), pointsPerPixel: 4) { device, queue, texture, pointsFilled, runsFilled, pointsUnfilled, runsUnfilled in
            applyMetalSuzuki(device: device, commandQueue: queue, texture: texture, pointsFilled: pointsFilled, runsFilled: runsFilled, pointsUnfilled: pointsUnfilled, runsUnfilled: runsUnfilled)
        }
    }
    
    func testDonut() throws {
        _ = PieceMetalSuzuki(imageUrl: url("donut"), coreSize: PixelSize(width: 1, height: 1), pointsPerPixel: 4) { device, queue, texture, pointsFilled, runsFilled, pointsUnfilled, runsUnfilled in
            applyMetalSuzuki(device: device, commandQueue: queue, texture: texture, pointsFilled: pointsFilled, runsFilled: runsFilled, pointsUnfilled: pointsUnfilled, runsUnfilled: runsUnfilled)
        }
    }
    
    func testIndirectLUT1x1() throws {
        let device = MTLCreateSystemDefaultDevice()!
        let coreSize = PixelSize(width: 1, height: 1)
        let tableWidth = 4
        let pointsPerPixel: UInt32 = 4
        let ltb = LookupTableBuilder(coreSize: coreSize, tableWidth: tableWidth, pointsPerPixel: pointsPerPixel)
        ltb.setBuffers(device: device)
        
        _ = PieceMetalSuzuki(imageUrl: url("square"), coreSize: coreSize, pointsPerPixel: pointsPerPixel) { device, queue, texture, pointsFilled, runsFilled, pointsUnfilled, runsUnfilled in
            applyMetalSuzuki_LUT(device: device, commandQueue: queue, texture: texture, pointsFilled: pointsFilled, runsFilled: runsFilled, pointsUnfilled: pointsUnfilled, runsUnfilled: runsUnfilled, coreSize: coreSize, tableWidth: tableWidth, pointsPerPixel: pointsPerPixel)
        }
    }
    
    func testIndirectLUT2x1() throws {
        let device = MTLCreateSystemDefaultDevice()!
        let coreSize = PixelSize(width: 2, height: 1)
        let tableWidth = 6
        let pointsPerPixel: UInt32 = 3
        let ltb = LookupTableBuilder(coreSize: coreSize, tableWidth: tableWidth, pointsPerPixel: pointsPerPixel)
        ltb.setBuffers(device: device)
        
        _ = PieceMetalSuzuki(imageUrl: url("waffle"), coreSize: coreSize, pointsPerPixel: pointsPerPixel) { device, queue, texture, pointsFilled, runsFilled, pointsUnfilled, runsUnfilled in
            applyMetalSuzuki_LUT(device: device, commandQueue: queue, texture: texture, pointsFilled: pointsFilled, runsFilled: runsFilled, pointsUnfilled: pointsUnfilled, runsUnfilled: runsUnfilled, coreSize: coreSize, tableWidth: tableWidth, pointsPerPixel: pointsPerPixel)
        }
    }
}
