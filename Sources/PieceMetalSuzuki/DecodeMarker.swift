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
    /// Markers are
    /// - equal in size,
    /// - close together – should undergo roughly equal perspective transformations.
    ///
    /// Hence their longest sides (whichever that is) should be equal in length.
    /// This defines the tolerance for error in that metric.
    /// e.g. `0.2` allows for 80% to 120%.
    public var longestSideLengthTolerance: Double
    
    /// Largest allowed angle.
    /// Ideally, as below, angle should be zero.
    /// Angle is positive, in radians.
    /// ```
    ///  +-----+ <- parallel with center vector  +-----+
    ///  |     |                                 |     |
    ///  |  X--|---------------------------------|--X  |
    ///  |     |                                 |     |
    ///  +-----+  parallel with center vector -> +-----+
    /// ```
    public var misalignmentTolerance: Double
    
    public static let starter = DoubleDiamondParameters(
        longestSideLengthTolerance: 0.15,
        misalignmentTolerance: .pi * 0.1
    )
}
}
