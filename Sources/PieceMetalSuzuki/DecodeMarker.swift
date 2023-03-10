//
//  File.swift
//  
//
//  Created by Secret Asian Man Dev on 19/2/23.
//

import Foundation
import CoreVideo

internal func findParallelograms(
    pointBuffer: Buffer<PixelPoint>,
    runBuffer: Buffer<Run>,
    runIndices: Range<Int>,
    parameters: RDPParameters,
    /// Used to scale quadrilaterals back up to size.
    scale: Double
) -> [Parallelogram] {
    return QuadProfiler.time(.overall) {
        let candidates = [Quadrilateral?].init(unsafeUninitializedCapacity: runIndices.count) { buffer, count in
            DispatchQueue.concurrentPerform(iterations: runIndices.count) { iteration in
                QuadProfiler.time(.overallSerial) {
                    /// Extract points from buffers.
                    let run = runBuffer.array[runIndices.startIndex + iteration]
                    let points = (run.oldTail..<run.oldHead).map { ptIdx in
                        let pixelPt = pointBuffer.array[Int(ptIdx)]
                        return DoublePoint(pixelPt)
                    }
                    
                    /// Check if the contour can be reduced to a nice quadrilateral.
                    buffer[iteration] = reduceToParallelogram(polyline: points, parameters: parameters)
                }
            }
            count = runIndices.count
        }
        return candidates
            .compactMap { $0 }
            .map { $0.scaled(by: scale) }
    }
}

internal func decodeMarkers(
    pixelBuffer: CVPixelBuffer,
    parallelograms: [Parallelogram],
    rdpParameters: RDPParameters = .starter
) -> Void {
    pixelBuffer.withLockedBaseAddress { token in
        for parallelogram in parallelograms {
            let samples = sampleSkewedGrid(
                pixelBuffer: pixelBuffer,
                token: token,
                quadrilateral: parallelogram,
                parameters: SkewedSampleParameters(marginSize: 0.1, gridSize: 3)
            )
            guard let samples else {
                debugPrint("Failed to sample regions")
                continue
            }
        }
    }
}

public struct DoubleDiamondParameters {
    public static let starter = DoubleDiamondParameters()
}

public struct DoubleDiamond {
    
    public let diamond1: Parallelogram
    public let diamond2: Parallelogram
    
    init(diamond1: Parallelogram, diamond2: Parallelogram) {
        self.diamond1 = diamond1
        self.diamond2 = diamond2
    }
}

/// Of the detected contours, which pair (if any) is most likely our stylus?
internal func findDoubleDiamond(
    parallelograms: [Parallelogram],
    parameters: DoubleDiamondParameters = .starter
) -> DoubleDiamond? {
    return nil
}
