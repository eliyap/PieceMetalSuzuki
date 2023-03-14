import XCTest
@testable import PieceMetalSuzuki

final class PieceMetalSuzukiTests: XCTestCase {
    
    func url(_ name: String) -> URL {
        Bundle.module.url(forResource: name, withExtension: ".png", subdirectory: "Images")!
    }
    
    func testDetection() async throws {
        let patternSize = PatternSize.w2h2
        let format = kCVPixelFormatType_32BGRA
        assert(loadLookupTablesProtoBuf(patternSize))
        
        let imageUrl = url("qrTilt")
        _ = PieceMetalSuzuki(imageUrl: imageUrl, patternSize: patternSize, format: format) { device, queue, texture, pixelBuffer, pointsFilled, runsFilled, pointsUnfilled, runsUnfilled in
            let borders = applyMetalSuzuki_LUT(device: device, commandQueue: queue, texture: texture, pointsFilled: pointsFilled, runsFilled: runsFilled, pointsUnfilled: pointsUnfilled, runsUnfilled: runsUnfilled, patternSize: patternSize)!
            let scale = 1.0
            measure {
                let quads = findParallelograms(
                    borders: borders,
                    parameters: RDPParameters(
                        minPoints: 10,
                        sideErrorLimit: 0.1,
                        aspectRatioErrorLimit: 0.5
                    ),
                    scale: scale
                )
                
                debugPrint("\(quads.count) quads")
                let found = findDoubleDiamond(parallelograms: quads)
                print("Found \(String(describing: found))")
            }
            saveBufferToPng(buffer: pixelBuffer, format: .BGRA8)
        }
        
        await QuadProfiler.report()
    }
    
    func testBgraImageManipulation() throws {
        let imageUrl = url("qrTilt")
        let ciImage = CIImage(contentsOf: imageUrl)!
        var pixelBuffer: CVPixelBuffer!
        CVPixelBufferCreate(
            kCFAllocatorDefault,
            Int(ciImage.extent.width),
            Int(ciImage.extent.height),
            kCVPixelFormatType_32BGRA,
            NSDictionary(),
            &pixelBuffer
        )
        CIContext().render(ciImage, to: pixelBuffer)
        
        /// Draw a diagonal line from top left to bottom right.
        CVPixelBufferLockBaseAddress(pixelBuffer, [])
        let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer)!
            .assumingMemoryBound(to: UInt8.self)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        for idx in 0..<min(width, height) {
            let pixel = baseAddress.advanced(by: (idx * bytesPerRow) + (idx * 4))
            pixel[0] = 255
            pixel[1] = 0
            pixel[2] = 0
            pixel[3] = 255
        }
        CVPixelBufferUnlockBaseAddress(pixelBuffer, [])

        saveBufferToPng(buffer: pixelBuffer, format: .RGBA8)
    }
    
    func testYCbCrImageManipulation() throws {
        let imageUrl = url("qrTilt")
        let ciImage = CIImage(contentsOf: imageUrl)!
        var pixelBuffer: CVPixelBuffer!
        CVPixelBufferCreate(
            kCFAllocatorDefault,
            Int(ciImage.extent.width),
            Int(ciImage.extent.height),
            kCVPixelFormatType_420YpCbCr8BiPlanarFullRange,
            NSDictionary(),
            &pixelBuffer
        )
        CIContext().render(ciImage, to: pixelBuffer)
        
        /// Draw a diagonal line from top left to bottom right.
        CVPixelBufferLockBaseAddress(pixelBuffer, [])
        let lumaPlaneIndex = 0
        let planeType = UInt8.self
        let baseAddress = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, lumaPlaneIndex)!
            .assumingMemoryBound(to: planeType)
        let bytesPerRow = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, lumaPlaneIndex)
        let width = CVPixelBufferGetWidthOfPlane(pixelBuffer, lumaPlaneIndex)
        let height = CVPixelBufferGetHeightOfPlane(pixelBuffer, lumaPlaneIndex)
        for idx in 0..<min(width, height) {
            let pixel = baseAddress.advanced(by: (idx * bytesPerRow) + idx)
            pixel[0] = 0
        }
        CVPixelBufferUnlockBaseAddress(pixelBuffer, [])

        saveBufferToPng(buffer: pixelBuffer, format: .RGBA8)
    }
}
