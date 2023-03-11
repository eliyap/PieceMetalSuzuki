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
    
    public var centerVector: DoubleVector {
        DoubleVector(start: diamond1.center, end: diamond2.center)
    }
    
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
    guard parallelograms.isEmpty == false else { return nil }
    var pairs = (0..<(parallelograms.count - 1)).flatMap { firstIdx in
        return ((firstIdx + 1)..<parallelograms.count).map { secondIdx in
            return DoubleDiamond(
                diamond1: parallelograms[firstIdx],
                diamond2: parallelograms[secondIdx]
            )
        }
    }
    
    for pair in pairs {
        /// Partition points by center vector.
        var above = (pair.diamond1.corners + pair.diamond2.corners)
            .filter { $0.displacement(from: pair.centerVector) > 0 }
        var below = (pair.diamond1.corners + pair.diamond2.corners)
            .filter { $0.displacement(from: pair.centerVector) < 0 }
        guard above.count == 4, below.count == 4 else {
            debugPrint("Unexpected partitioning. Above: \(above.count), below: \(below.count)")
            continue
        }
        
        /**
         Use dot product to find how far "along" a vector some point is, in the direction of the vector.
         ```
           end ->      ^
                      /                   (b) <- larger dot product,
                     /                           further in direction of vector
                    /
         start ->  /     (a) <- small dot product, not "far along"
         ```
         */
        func distanceAlong(for point: DoublePoint) -> Double {
            pair.centerVector.dot(DoubleVector(start: pair.centerVector.start, end: point))
        }
        above.sort { lhs, rhs in distanceAlong(for: lhs) < distanceAlong(for: rhs) }
        below.sort { lhs, rhs in distanceAlong(for: lhs) < distanceAlong(for: rhs) }
        
        let aboveLine = DoubleVector(start: above.first!, end: above.last!)
        let belowLine = DoubleVector(start: below.first!, end: below.last!)
        
        /// Clockwise ordering for new quadrilateral.
        let corner1 = above.first!
        let corner2 = above.last!
        let corner3 = below.last!
        let corner4 = below.first!
        
        /// Check that remaining points are colinear.
        let colinear = AbsoluteTolerance(target: 0, maxError: 0.1)
        func isRoughlyColinear(point: DoublePoint, line: DoubleVector) -> Bool {
            let normalized = point.distance(from: line) / line.magnitude
            return normalized.isWithin(colinear)
        }
        guard
            isRoughlyColinear(point: above[1], line: aboveLine),
            isRoughlyColinear(point: above[2], line: aboveLine),
            isRoughlyColinear(point: below[1], line: belowLine),
            isRoughlyColinear(point: below[2], line: belowLine)
        else {
            debugPrint("Points are not colinear")
            continue
        }
        
        /// Deskew remaining points.
        let quadrilateral = Quadrilateral(corner1: corner1, corner2: corner2, corner3: corner3, corner4: corner4)
        
        guard
            let matrix = matrixFor(quadrilateral: quadrilateral),
            let tAbove1 = above[1].transformed(by: matrix),
            let tAbove2 = above[2].transformed(by: matrix),
            let tBelow1 = below[1].transformed(by: matrix),
            let tBelow2 = below[2].transformed(by: matrix)
        else {
            debugPrint("Failed to deskew points")
            continue
        }

        /// ```
        ///  +-----+          ~8.75 square           +-----+
        ///  |     |           side length           |     |
        ///  |  X--|---------------------------------|--X  |
        ///  |     |                                 |     |
        ///  +-----+                                 +-----+
        /// ```
        let centerSideRatio = ProportionalTolerance(target: 1.0 / (8.75 + 1.0), maxError: 0.25)
        guard
            (tAbove1.y - 0).isWithin(centerSideRatio),
            (1 - tAbove2.y).isWithin(centerSideRatio),
            (tBelow1.y - 0).isWithin(centerSideRatio),
            (1 - tBelow2.y).isWithin(centerSideRatio)
        else {
            // debugPrint("Points are not in expected positions")
            // debugPrint("tAbove1: \(tAbove1)")
            // debugPrint("tAbove2: \(tAbove2)")
            // debugPrint("tBelow1: \(tBelow1)")
            // debugPrint("tBelow2: \(tBelow2)")
            continue
       }

        return pair
    }
    
    
    return nil
}
