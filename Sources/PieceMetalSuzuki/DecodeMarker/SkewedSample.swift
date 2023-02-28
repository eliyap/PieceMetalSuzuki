//
//  File.swift
//  
//
//  Created by Secret Asian Man Dev on 22/2/23.
//

import Foundation
import CoreVideo

struct SkewedSampleParameters {
    /// Proportion of the side length to ignore.
    /// e.g. 0.5 would ignore the whole image.
    public let marginSize: Double
    
    /// Side length of the grid.
    /// e.g. `3` would result in a 3x3 grid.
    public let gridSize: Int
}

struct CellSample {
    /// Brightness found across all sampled pixels.
    public var totalLuminosity: Double = 0.0
    
    /// Total number of pixels sampled.
    public var sampleCount: Int = 0
    
    public var meanLuminosity: Double {
        guard sampleCount > 0 else { return .zero }
        return totalLuminosity / Double(sampleCount)
    }
}

func sampleSkewedGrid(
    pixelBuffer: CVPixelBuffer,
    token: PixelBufferBaseAddressLockToken,
    quadrilateral: Quadrilateral,
    parameters: SkewedSampleParameters
) -> [[CellSample]]? {
    /// Assumed BGRA format.
    guard supportedFormats.contains(CVPixelBufferGetPixelFormatType(pixelBuffer)) else {
        assertionFailure("Unsupported pixel format")
        debugPrint("Unsupported pixel format \(CVPixelBufferGetPixelFormatName(pixelBuffer))")
        return nil
    }
    
    guard let matrix = matrixFor(quadrilateral: quadrilateral) else {
        debugPrint("Singular matrix")
        return nil
    }

    var result: [[CellSample]] = Array(repeating: Array(repeating: CellSample(), count: parameters.gridSize), count: parameters.gridSize)
    
    let width = CVPixelBufferGetWidth(pixelBuffer)
    let height = CVPixelBufferGetHeight(pixelBuffer)
    for row in quadrilateral.yPixelBounds where (0..<height).contains(row) {
        for col in quadrilateral.xPixelBounds where (0..<width).contains(col) {
            /// Map point to the unit square, if possible
            let point = DoublePoint(x: Double(col), y: Double(row))
            guard let transformed = point.transformed(by: matrix) else {
                continue
            }

            /// Map unit point to region grid.
            /// Suppose a point is at `(1, 1)` in the grid. We want to fill all pixels from `1.0..<2.0` in the unit square, so
            /// `x = marginSize + ((1.1 or something) / gridSize) * (1 - 2*marginSize)`
            /// To recover the row value from `x`, we should round values in `1.0..<2.0` with `.down` to `1`.
            let gridX = Double(parameters.gridSize) * (transformed.x - parameters.marginSize) / (1 - 2 * parameters.marginSize)
            let gridY = Double(parameters.gridSize) * (transformed.y - parameters.marginSize) / (1 - 2 * parameters.marginSize)
            let gridRow = Int(gridX.rounded(.down)) 
            let gridCol = Int(gridY.rounded(.down))

            guard (0..<parameters.gridSize) ~= gridRow, (0..<parameters.gridSize) ~= gridCol else {
                continue
            }

            /// Extract pixel data.
            result[gridRow][gridCol].totalLuminosity += luminosity(row: row, col: col, in: pixelBuffer, token: token)
            result[gridRow][gridCol].sampleCount += 1
            
        }
    }
    
    return result
}

public let supportedFormats: [OSType] = [
    kCVPixelFormatType_32BGRA,
    kCVPixelFormatType_420YpCbCr8BiPlanarFullRange,
]

/// https://developer.apple.com/documentation/technotes/tn3121-selecting-a-pixel-format-for-an-avcapturevideodataoutput
func luminosity(row: Int, col: Int, in pixelBuffer: CVPixelBuffer, token: PixelBufferBaseAddressLockToken) -> Double {
    switch CVPixelBufferGetPixelFormatType(pixelBuffer) {
    case kCVPixelFormatType_32BGRA:
        let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer)!.assumingMemoryBound(to: UInt8.self)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
        let bgraMax = 255.0
        let bgraWidth = 4
        
        let pixel = baseAddress.advanced(by: (row * bytesPerRow) + (col * bgraWidth))
        let b = Double(pixel[0]) / bgraMax
        let g = Double(pixel[1]) / bgraMax
        let r = Double(pixel[2]) / bgraMax

        /// https://en.wikipedia.org/wiki/Grayscale
        let luminosity = Double(r) * 0.2126 + Double(g) * 0.7152 + Double(b) * 0.0722
        return luminosity
    
    case kCVPixelFormatType_420YpCbCr8BiPlanarFullRange:
        let yPlaneIndex = 0
        let lumaMax = 255.0
        let baseAddress = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, yPlaneIndex)!.assumingMemoryBound(to: UInt8.self)
        let bytesPerRow = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, yPlaneIndex)
        let luminosity = baseAddress[(row * bytesPerRow) + col]
        return Double(luminosity) / lumaMax
    
    default:
        assertionFailure("Unsupported pixel format")
        debugPrint("Unsupported pixel format \(CVPixelBufferGetPixelFormatName(pixelBuffer))")
        return 0
    }
}
