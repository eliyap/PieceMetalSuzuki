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

public struct DoubleDiamond {
    
    public let diamond1: Parallelogram
    public let diamond2: Parallelogram
    
    internal let longestSideLengthRatioError: Double
    
    /// A measure of how well aligned each diamond is with the line between them.
    /// If no angles are eligible, value is `nil` and this struct should be disqualified.
    internal let misalignment: Double?

    init(diamond1: Parallelogram, diamond2: Parallelogram) {
        self.diamond1 = diamond1
        self.diamond2 = diamond2
        
        self.longestSideLengthRatioError = {
            func longestSide(_ p: Parallelogram) -> Double {
                p.sides.map { $0.magnitude }.max()!
            }
            return abs(1.0 - (longestSide(diamond1) / longestSide(diamond2)))
        }()
        
        self.misalignment = { () -> Double? in
            let centerVector = DoubleVector(start: diamond1.center, end: diamond2.center)
            
            /// Both diamonds should have a best-aligned side (minimum angle against center vector).
            /// Return the worse angle of the two best-aligned sides.
            let angles1 = diamond1.sides.compactMap { $0.angle(to: centerVector) }
            let angles2 = diamond2.sides.compactMap { $0.angle(to: centerVector) }
            if angles1.isEmpty || angles2.isEmpty {
                return nil
            } else {
                return max(angles1.min()!, angles2.min()!)
            }
        }()
    }
}

/// Of the detected contours, which pair (if any) is most likely our stylus?
internal func findDoubleDiamond(
    parallelograms: [Parallelogram],
    parameters: DoubleDiamondParameters = .starter
) -> DoubleDiamond? {
    guard parallelograms.isEmpty == false else { return nil }
    var pairs = (0..<(parallelograms.count - 1)).flatMap { firstIdx in
        return ((firstIdx + 1)..<parallelograms.count).map { secondIdx in
            return DoubleDiamond(
                diamond1: parallelograms[firstIdx],
                diamond2: parallelograms[secondIdx]
            )
        }
    }
    
    pairs = pairs.filter({ candidate in
        guard let misalignment = candidate.misalignment else { return false }
        return (misalignment < parameters.misalignmentTolerance)
            && (candidate.longestSideLengthRatioError < parameters.longestSideLengthTolerance)
    })
    
    return pairs.min { lhs, rhs in
        lhs.longestSideLengthRatioError < rhs.longestSideLengthRatioError
    }
}
