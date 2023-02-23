//
//  File.swift
//  
//
//  Created by Secret Asian Man Dev on 19/2/23.
//

import Foundation
import CoreVideo

internal func decodeMarkers(
    pixelBuffer: CVPixelBuffer,
    pointBuffer: Buffer<PixelPoint>,
    runBuffer: Buffer<Run>,
    runIndices: Range<Int>,
    rdpParameters: RDPParameters = .starter
) -> Void {
    CVPixelBufferLockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
    let addr = CVPixelBufferGetBaseAddress(pixelBuffer)!
        .assumingMemoryBound(to: UInt8.self)
    
    for runIdx in runIndices {
        let run = runBuffer.array[runIdx]
        let points = (run.oldTail..<run.oldHead).map { ptIdx in
            let pixelPt = pointBuffer.array[Int(ptIdx)]
            return DoublePoint(pixelPt)
        }
        
        guard let quad = checkQuadrilateral(polyline: points) else {
            continue
        }
        
        let samples = sampleSkewedGrid(
            pixelBuffer: pixelBuffer,
            baseAddress: addr,
            quadrilateral: quad,
            parameters: SkewedSampleParameters(marginSize: 0.1, gridSize: 3)
        )
        guard let samples else {
            debugPrint("Failed to sample regions")
            continue
        }
    }
    CVPixelBufferUnlockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
}
