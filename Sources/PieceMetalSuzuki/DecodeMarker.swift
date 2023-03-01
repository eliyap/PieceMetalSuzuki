//
//  File.swift
//  
//
//  Created by Secret Asian Man Dev on 19/2/23.
//

import Foundation
import CoreVideo

internal func findCandidateQuadrilaterals(
    pointBuffer: Buffer<PixelPoint>,
    runBuffer: Buffer<Run>,
    runIndices: Range<Int>,
    parameters: RDPParameters
) -> [Quadrilateral] {
    let candidates = [Quadrilateral?].init(unsafeUninitializedCapacity: runIndices.count) { buffer, count in
        for (idx, runIndex) in runIndices.enumerated() {
            /// Extract points from buffers.
            let run = runBuffer.array[runIndex]
            let points = (run.oldTail..<run.oldHead).map { ptIdx in
                let pixelPt = pointBuffer.array[Int(ptIdx)]
                return DoublePoint(pixelPt)
            }
            
            /// Check if the contour can be reduced to a nice quadrilateral.
            buffer[idx] = checkQuadrilateral(polyline: points, parameters: parameters)
        }
        count = runIndices.count
    }
    return candidates.compactMap { $0 }
}

internal func decodeMarkers(
    pixelBuffer: CVPixelBuffer,
    quadrilaterals: [Quadrilateral],
    rdpParameters: RDPParameters = .starter
) -> Void {
    pixelBuffer.withLockedBaseAddress { token in
        for quadrilateral in quadrilaterals {
            let samples = sampleSkewedGrid(
                pixelBuffer: pixelBuffer,
                token: token,
                quadrilateral: quadrilateral,
                parameters: SkewedSampleParameters(marginSize: 0.1, gridSize: 3)
            )
            guard let samples else {
                debugPrint("Failed to sample regions")
                continue
            }
        }
    }
}
