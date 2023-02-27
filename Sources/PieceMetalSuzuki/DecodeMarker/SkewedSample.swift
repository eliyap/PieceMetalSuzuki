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
    baseAddress: UnsafeMutablePointer<UInt8>,
    quadrilateral: Quadrilateral,
    parameters: SkewedSampleParameters
) -> [[CellSample]]? {
    /// Assumed BGRA format.
    guard CVPixelBufferGetPixelFormatType(pixelBuffer) == kCVPixelFormatType_32BGRA else {
        assertionFailure("Unsupported pixel format")
        debugPrint("Unsupported pixel format \(CVPixelBufferGetPixelFormatName(pixelBuffer))")
        return nil
    }
    let bgraWidth = 4
    let bgraMax = 255.0
    
    guard let matrix = matrixFor(quadrilateral: quadrilateral) else {
        debugPrint("Singular matrix")
        return nil
    }

    var result: [[CellSample]] = Array(repeating: Array(repeating: CellSample(), count: parameters.gridSize), count: parameters.gridSize)
    
    let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
    let width = CVPixelBufferGetWidth(pixelBuffer)
    let height = CVPixelBufferGetHeight(pixelBuffer)
    for row in quadrilateral.yPixelBounds where (0..<height).contains(row) {
        for col in quadrilateral.xPixelBounds where (0..<width).contains(col) {
            /// Map point to the unit square.
            let point = DoublePoint(x: Double(col), y: Double(row))
            let transformed = point.transformed(by: matrix)

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
            let pixel = baseAddress.advanced(by: (row * bytesPerRow) + (col * bgraWidth))
            let b = Double(pixel[0]) / bgraMax
            let g = Double(pixel[1]) / bgraMax
            let r = Double(pixel[2]) / bgraMax
            
            /// https://en.wikipedia.org/wiki/Grayscale
            let luminosity = Double(r) * 0.2126 + Double(g) * 0.7152 + Double(b) * 0.0722
            result[gridRow][gridCol].totalLuminosity += luminosity
            result[gridRow][gridCol].sampleCount += 1
        }
    }
    
    return result
}
