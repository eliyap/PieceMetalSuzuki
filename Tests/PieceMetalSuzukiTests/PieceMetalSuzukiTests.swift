import XCTest
@testable import PieceMetalSuzuki

final class PieceMetalSuzukiTests: XCTestCase {
    
    func url(_ name: String) -> URL {
        Bundle.module.url(forResource: name, withExtension: ".png", subdirectory: "Images")!
    }
    
    func testDetection() throws {
        let patternSize = PatternSize.w2h2
        assert(loadLookupTables(patternSize))
        
        let imageUrl = url("ticTacToe")
        _ = PieceMetalSuzuki(imageUrl: imageUrl, patternSize: patternSize) { device, queue, texture, pixelBuffer, pointsFilled, runsFilled, pointsUnfilled, runsUnfilled in
            let runIndices = applyMetalSuzuki_LUT(device: device, commandQueue: queue, texture: texture, pointsFilled: pointsFilled, runsFilled: runsFilled, pointsUnfilled: pointsUnfilled, runsUnfilled: runsUnfilled, patternSize: patternSize)!
            let quads = findCandidateQuadrilaterals(pointBuffer: pointsFilled, runBuffer: runsFilled, runIndices: runIndices)
            decodeMarkers(pixelBuffer: pixelBuffer, quadrilaterals: quads)
            saveBufferToPng(buffer: pixelBuffer, format: .BGRA8)
        }
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
