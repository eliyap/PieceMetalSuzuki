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
            _ = PieceMetalSuzuki(imageUrl: url("input"), patternSize: .w1h1) { device, queue, texture, pointsFilled, runsFilled, pointsUnfilled, runsUnfilled in
                applyMetalSuzuki(device: device, commandQueue: queue, texture: texture, pointsFilled: pointsFilled, runsFilled: runsFilled, pointsUnfilled: pointsUnfilled, runsUnfilled: runsUnfilled)
            }
        }
        
        await Profiler.report()
    }
    
    func testWaffle() throws {
        _ = PieceMetalSuzuki(imageUrl: url("waffle"), patternSize: .w1h1) { device, queue, texture, pointsFilled, runsFilled, pointsUnfilled, runsUnfilled in
            applyMetalSuzuki(device: device, commandQueue: queue, texture: texture, pointsFilled: pointsFilled, runsFilled: runsFilled, pointsUnfilled: pointsUnfilled, runsUnfilled: runsUnfilled)
        }
    }
    
    func testWhite() throws {
        _ = PieceMetalSuzuki(imageUrl: url("white"), patternSize: .w1h1) { device, queue, texture, pointsFilled, runsFilled, pointsUnfilled, runsUnfilled in
            applyMetalSuzuki(device: device, commandQueue: queue, texture: texture, pointsFilled: pointsFilled, runsFilled: runsFilled, pointsUnfilled: pointsUnfilled, runsUnfilled: runsUnfilled)
        }
    }
    
    func testDots() throws {
        _ = PieceMetalSuzuki(imageUrl: url("dots"), patternSize: .w1h1) { device, queue, texture, pointsFilled, runsFilled, pointsUnfilled, runsUnfilled in
            applyMetalSuzuki(device: device, commandQueue: queue, texture: texture, pointsFilled: pointsFilled, runsFilled: runsFilled, pointsUnfilled: pointsUnfilled, runsUnfilled: runsUnfilled)
        }
    }
    
    func testDiamonds() throws {
        _ = PieceMetalSuzuki(imageUrl: url("diamonds"), patternSize: .w1h1) { device, queue, texture, pointsFilled, runsFilled, pointsUnfilled, runsUnfilled in
            applyMetalSuzuki(device: device, commandQueue: queue, texture: texture, pointsFilled: pointsFilled, runsFilled: runsFilled, pointsUnfilled: pointsUnfilled, runsUnfilled: runsUnfilled)
        }
    }
    
    func testSquare() throws {
        _ = PieceMetalSuzuki(imageUrl: url("square"), patternSize: .w1h1) { device, queue, texture, pointsFilled, runsFilled, pointsUnfilled, runsUnfilled in
            applyMetalSuzuki(device: device, commandQueue: queue, texture: texture, pointsFilled: pointsFilled, runsFilled: runsFilled, pointsUnfilled: pointsUnfilled, runsUnfilled: runsUnfilled)
        }
    }
    
    func testDonut() throws {
        _ = PieceMetalSuzuki(imageUrl: url("donut"), patternSize: .w1h1) { device, queue, texture, pointsFilled, runsFilled, pointsUnfilled, runsUnfilled in
            applyMetalSuzuki(device: device, commandQueue: queue, texture: texture, pointsFilled: pointsFilled, runsFilled: runsFilled, pointsUnfilled: pointsUnfilled, runsUnfilled: runsUnfilled)
        }
    }
    
    func testIndirectLUT1x1() throws {
        let device = MTLCreateSystemDefaultDevice()!
        let patternSize = PatternSize.w1h1
        let ltb = LookupTableBuilder(patternSize: patternSize)
        ltb.setBuffers()
        
        _ = PieceMetalSuzuki(imageUrl: url("square"), patternSize: patternSize) { device, queue, texture, pointsFilled, runsFilled, pointsUnfilled, runsUnfilled in
            applyMetalSuzuki_LUT(device: device, commandQueue: queue, texture: texture, pointsFilled: pointsFilled, runsFilled: runsFilled, pointsUnfilled: pointsUnfilled, runsUnfilled: runsUnfilled, patternSize: patternSize)
        }
    }
    
    func testIndirectLUT2x1() async throws {
        let patternSize = PatternSize.w2h1
        let ltb = LookupTableBuilder(patternSize: patternSize)
        ltb.setBuffers()
        
        measure {
            _ = PieceMetalSuzuki(imageUrl: url("input"), patternSize: patternSize) { device, queue, texture, pointsFilled, runsFilled, pointsUnfilled, runsUnfilled in
                applyMetalSuzuki_LUT(device: device, commandQueue: queue, texture: texture, pointsFilled: pointsFilled, runsFilled: runsFilled, pointsUnfilled: pointsUnfilled, runsUnfilled: runsUnfilled, patternSize: patternSize)
            }
        }
        
        await Profiler.report()
    }
    
    func testIndirectLUT2x2() async throws {
        let patternSize = PatternSize.w2h2
        
        /// Generate LUT from scratch.
//        let ltb = LookupTableBuilder(patternSize: patternSize)
//        ltb.setBuffers()
        
        /// Load LUT from JSON.
        loadLookupTables(patternSize)
        
        measure {
            _ = PieceMetalSuzuki(imageUrl: url("input"), patternSize: patternSize) { device, queue, texture, pointsFilled, runsFilled, pointsUnfilled, runsUnfilled in
                applyMetalSuzuki_LUT(device: device, commandQueue: queue, texture: texture, pointsFilled: pointsFilled, runsFilled: runsFilled, pointsUnfilled: pointsUnfilled, runsUnfilled: runsUnfilled, patternSize: patternSize)
            }
        }

        await Profiler.report()
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
        
        let imageUrl = url("aruco")
        
        let ciImage = CIImage(contentsOf: imageUrl)!
        
        /// Make a pixel buffer.
        var width = Int(ciImage.extent.width)
        let height = Int(ciImage.extent.height)
        let format = kCVPixelFormatType_32BGRA
        let options: NSDictionary = [
            kCVPixelBufferCGImageCompatibilityKey: true,
            kCVPixelBufferMetalCompatibilityKey: true,
        ]
        var buffer: CVPixelBuffer!
        CVPixelBufferCreate(kCFAllocatorDefault, width, height, format, options, &buffer)

        /// Copy image to pixel buffer.
        let context = CIContext()
        context.render(ciImage, to: buffer)
        
        width += 0

        CVPixelBufferLockBaseAddress(buffer, CVPixelBufferLockFlags(rawValue: 0))
        
        _ = PieceMetalSuzuki(imageUrl: imageUrl, patternSize: patternSize) { device, queue, texture, pointsFilled, runsFilled, pointsUnfilled, runsUnfilled in
            let runIndices = applyMetalSuzuki_LUT(device: device, commandQueue: queue, texture: texture, pointsFilled: pointsFilled, runsFilled: runsFilled, pointsUnfilled: pointsUnfilled, runsUnfilled: runsUnfilled, patternSize: patternSize)!
            for runIdx in runIndices {
                let run = runsFilled.array[runIdx]
                let points = (run.oldTail..<run.oldHead).map { ptIdx in
                    let pixelPt = pointsFilled.array[Int(ptIdx)]
                    return DoublePoint(pixelPt)
                }
                
                let corners = checkQuadrangle(polyline: points)
                
                guard let corners else{ continue }
                let (c1, c2, c3, c4) = corners

                print("Run \(runIdx) has \(points.count) points")
                
                let addr = CVPixelBufferGetBaseAddress(buffer)!
                    .assumingMemoryBound(to: UInt8.self)
                (run.oldTail..<run.oldHead).forEach { ptIdx in
                    let pixelPt = pointsFilled.array[Int(ptIdx)]
                    // Mark pixel.
                    let offset = (Int(pixelPt.y) * width + Int(pixelPt.x)) * 4
                    let pixel = addr.advanced(by: offset)
                    pixel[0] = 0
                    pixel[1] = 0
                    pixel[2] = 255
                    pixel[3] = 255
                }
            }
        }
        
        CVPixelBufferUnlockBaseAddress(buffer, CVPixelBufferLockFlags(rawValue: 0))
        saveBufferToPng(buffer: buffer, format: .RGBA8)
    }
}
