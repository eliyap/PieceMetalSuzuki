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
}

func samples(
    pixelBuffer: CVPixelBuffer,
    baseAddress: UnsafeMutablePointer<UInt8>,
    quadrilateral: Quadrilateral,
    parameters: SkewedSampleParameters
) -> Void {
    /// Assumed BGRA format.
    guard CVPixelBufferGetPixelFormatType(pixelBuffer) == kCVPixelFormatType_32BGRA else {
        assertionFailure("Unsupported pixel format")
        return
    }
    let bgraWidth = 4
    let bgraMax = 255.0
    
    guard let matrix = matrixFor(quadrilateral: quadrilateral) else {
        debugPrint("Singular matrix")
        return
    }

    var result: [[CellSample]] = Array(repeating: Array(repeating: CellSample(), count: parameters.gridSize), count: parameters.gridSize)
    
    let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
    let width = CVPixelBufferGetWidth(pixelBuffer)
    let height = CVPixelBufferGetHeight(pixelBuffer)
    for row in quadrilateral.xPixelBounds where (0..<height).contains(row) {
        for col in quadrilateral.yPixelBounds where (0..<width).contains(col) {
            /// Map point to the unit square.
            let point = DoublePoint(x: Double(col), y: Double(row))
            let transformed = point.transformed(by: matrix)

            /// Map unit point to region grid.
            let gridRow = Int(Double(parameters.gridSize) * (transformed.x - parameters.marginSize) / (1 - 2 * parameters.marginSize))
            let gridCol = Int(Double(parameters.gridSize) * (transformed.y - parameters.marginSize) / (1 - 2 * parameters.marginSize))
            guard (0..<parameters.gridSize) ~= gridRow, (0..<parameters.gridSize) ~= gridCol else {
                continue
            }

            /// Extract pixel data.
            let pixel = (row * bytesPerRow) + (col * bgraWidth)
            let b = Double(baseAddress[pixel + 0]) / bgraMax
            let g = Double(baseAddress[pixel + 1]) / bgraMax
            let r = Double(baseAddress[pixel + 2]) / bgraMax
            
            /// https://en.wikipedia.org/wiki/Grayscale
            let luminosity = Double(r) * 0.2126 + Double(g) * 0.7152 + Double(b) * 0.0722
            result[gridRow][gridCol].totalLuminosity += luminosity
            result[gridRow][gridCol].sampleCount += 1
        }
    }
}
