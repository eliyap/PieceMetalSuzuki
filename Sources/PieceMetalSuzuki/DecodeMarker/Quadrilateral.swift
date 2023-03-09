//  Quadrilateral.swift
//  Created by Secret Asian Man Dev on 22/2/23.

import Foundation

/**
 ```
   -----
  /    /
 /    /
 -----
 ```
 The contour we expect to find in images is a *parallelogram*.
 The small, square markers can be
 - tilted away from the camera, making rectangles
 - rotated, making rhombi
 - both, making parallelograms.
 
 This excludes certain quadrilaterals which we will reject, such as
 - kites
 - trapezoids
 */
public typealias Parallelogram = Quadrilateral

public struct Quadrilateral { 
    public let corner1: DoublePoint
    public let corner2: DoublePoint
    public let corner3: DoublePoint
    public let corner4: DoublePoint
    
    public init(corner1: DoublePoint, corner2: DoublePoint, corner3: DoublePoint, corner4: DoublePoint) {
        self.corner1 = corner1
        self.corner2 = corner2
        self.corner3 = corner3
        self.corner4 = corner4
    }
    
    var xPixelBounds: Range<Int> {
        let xMin = min(corner1.x, corner2.x, corner3.x, corner4.x)
        let xPixelMin = Int(xMin.rounded(.down))
        let xMax = max(corner1.x, corner2.x, corner3.x, corner4.x)
        let xPixelMax = Int(xMax.rounded(.up))
        return xPixelMin..<xPixelMax
    }

    var yPixelBounds: Range<Int> {
        let yMin = min(corner1.y, corner2.y, corner3.y, corner4.y)
        let yPixelMin = Int(yMin.rounded(.down))
        let yMax = max(corner1.y, corner2.y, corner3.y, corner4.y)
        let yPixelMax = Int(yMax.rounded(.up))
        return yPixelMin..<yPixelMax
    }
    
    func scaled(by scale: Double) -> Self {
        Self.init(
            corner1: DoublePoint(x: corner1.x * scale, y: corner1.y * scale),
            corner2: DoublePoint(x: corner2.x * scale, y: corner2.y * scale),
            corner3: DoublePoint(x: corner3.x * scale, y: corner3.y * scale),
            corner4: DoublePoint(x: corner4.x * scale, y: corner4.y * scale)
        )
    }
}

extension Quadrilateral {
    var center: DoublePoint {
        DoublePoint(
            x: (corner1.x + corner2.x + corner3.x + corner4.x) / 4.0,
            y: (corner1.y + corner2.y + corner3.y + corner4.y) / 4.0
        )
    }

    var sides: [DoubleVector] {
        [
            DoubleVector(start: corner1, end: corner2),
            DoubleVector(start: corner2, end: corner3),
            DoubleVector(start: corner3, end: corner4),
            DoubleVector(start: corner4, end: corner1),
        ]
    }
}

/// Based on a version of Ramer-Douglas-Peucker
/// https://en.wikipedia.org/wiki/Ramer%E2%80%93Douglas%E2%80%93Peucker_algorithm
/// Loosely inspired by OpenCV's implementation.
public struct RDPParameters {
    public var minPoints: Int
    
    /// Maximum allowed deviation of points, relative to the length of the diagonal.
    /// For a quadrangle with straight sides, that distance would be zero.
    public let sideErrorLimit: Double
    
    /// Maximum allowed deviation from a square aspect ratio of `1.0`.
    public let aspectRatioErrorLimit: Double
    
    public static let starter = RDPParameters(
        minPoints: 10,
        sideErrorLimit: 0.10,
        aspectRatioErrorLimit: 0.15
    )
}

internal func reduceToParallelogram(
    polyline: [DoublePoint],
    parameters: RDPParameters
) -> Parallelogram? {
    guard polyline.count > parameters.minPoints else {
        #if SHOW_RDP_WORK
        debugPrint("[RDP] Too few points")
        #endif
        return nil
    }
    
    /// 1. Find the center of the shape.
    let center = DoublePoint(
        x: polyline.map({ $0.x }).reduce(0, +) / Double(polyline.count),
        y: polyline.map({ $0.y }).reduce(0, +) / Double(polyline.count)
    )
    #if SHOW_RDP_WORK
    debugPrint("[RDP] Center: \(center)")
    #endif
    
    /// 2. Find the point furthest from the center, call this A
    let __start2 = CFAbsoluteTimeGetCurrent()
    var distSquaredFromCenter: [Double] = []
    for pt in polyline {
        let x2 = (pt.x - center.x) * (pt.x - center.x)
        let y2 = (pt.y - center.y) * (pt.y - center.y)
        distSquaredFromCenter.append(x2 + y2)
    }
    let idxFarthestFromCenter = distSquaredFromCenter.firstIndex(of: distSquaredFromCenter.max()!)! 
    let __end2 = CFAbsoluteTimeGetCurrent()
    QuadProfiler.add(__end2 - __start2, to: .findFurthest)
    
    /// 3. With the line from center to A, find 2 points along the line perpendicular to this line.
    let farthest = polyline[idxFarthestFromCenter]
    let dx = farthest.x - center.x
    let dy = farthest.y - center.y
    let p0 = DoublePoint(x: farthest.x - dy, y: farthest.y + dx)
    let p1 = DoublePoint(x: farthest.x + dy, y: farthest.y - dx)
    #if SHOW_RDP_WORK
    debugPrint("[RDP] farthest: \(farthest)")
    debugPrint("[RDP] p0: \(p0), p1: \(p1)")
    #endif

    /// 4. Find the point farthest from this line.
    /// That should be the quadrangle's opposite corner.
    let __start4 = CFAbsoluteTimeGetCurrent()
    var distFromLine: [Double] = []
    for pt in polyline {
        distFromLine.append(pt.distance(p0: p0, p1: p1))
    }
    let idxFarthestFromLine = distFromLine.firstIndex(of: distFromLine.max()!)!
    let __end4 = CFAbsoluteTimeGetCurrent()
    QuadProfiler.add(__end4 - __start4, to: .findOpposite)

    /// 5. Find the 2 extrema in distance from this line.
    /// i.e. treating the line as horizontal, find the points farthest above and below this line.
    /// These should be the remaining 2 corners.
    let __start5 = CFAbsoluteTimeGetCurrent()
    let corner1 = polyline[idxFarthestFromCenter]
    let corner3 = polyline[idxFarthestFromLine]
    var dispFromDiagonal: [Double] = []
    for pt in polyline {
        dispFromDiagonal.append(pt.displacement(p0: corner1, p1: corner3))
    }

    let corner2Idx = dispFromDiagonal.firstIndex(of: dispFromDiagonal.min()!)!
    let corner4Idx = dispFromDiagonal.firstIndex(of: dispFromDiagonal.max()!)!
    let corner2 = polyline[corner2Idx]
    let corner4 = polyline[corner4Idx]
    let __end5 = CFAbsoluteTimeGetCurrent()
    QuadProfiler.add(__end5 - __start5, to: .findExtrema)

    guard
        (corner1 != corner2) && (corner1 != corner3) && (corner1 != corner4),
        (corner2 != corner3) && (corner2 != corner4),
        (corner3 != corner4)
    else {
        #if SHOW_RDP_WORK
        debugPrint("[RDP] Identical corners")
        #endif
        return nil
    }

    /// 6. With these 4 points as corners, check if all points are within threshold of the lines between these points.
    let threshold = corner1.distance(to: corner3) * parameters.sideErrorLimit
    let withinLines = polyline.allSatisfy { pt in
        if pt == corner1 || pt == corner2 || pt == corner3 || pt == corner4 {
            return true
        }
        let alongLines = false
            || (pt.distance(p0: corner1, p1: corner2) < threshold)
            || (pt.distance(p0: corner2, p1: corner3) < threshold)
            || (pt.distance(p0: corner3, p1: corner4) < threshold)
            || (pt.distance(p0: corner4, p1: corner1) < threshold)
        
        #if SHOW_RDP_WORK
        if !alongLines {
            debugPrint("[RDP] Failed due to point \(pt)")
            debugPrint("\(pt.distance(p0: corner1, p1: corner2))")
            debugPrint("\(pt.distance(p0: corner2, p1: corner3))")
            debugPrint("\(pt.distance(p0: corner3, p1: corner4))")
            debugPrint("\(pt.distance(p0: corner4, p1: corner1))")
        }
        #endif
        
        return alongLines
    }

    guard withinLines else {
        #if SHOW_RDP_WORK
        debugPrint("[RDP] Failed due to points not along lines")
        #endif
        return nil
    }
    
    /// Check whether quadrilateral is parallelogram-y enough.
    /// This means opposite sides should be approximately equal in length.
    let aspRatioError = max(
        abs(1.0 - (corner1.distance(to: corner2) / corner3.distance(to: corner4))),
        abs(1.0 - (corner2.distance(to: corner3) / corner1.distance(to: corner4)))
    )
    guard aspRatioError < parameters.aspectRatioErrorLimit else {
        #if SHOW_RDP_WORK
        debugPrint("[RDP] Failed due to aspect ratio error \(aspRatioError)")
        print("aspRatio \(aspRatio) \(parameters.aspectRatioErrorLimit)")
        #endif
        return nil
    }
    
    return Quadrilateral(
        corner1: corner1,
        corner2: corner2,
        corner3: corner3,
        corner4: corner4
    )
}
