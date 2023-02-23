//
//  Quadrilateral.swift
//  Aruco
//
//  Created by Secret Asian Man Dev on 22/2/23.
//

import Foundation
import OrderedCollections

struct Quadrilateral { 
    public let corner1: DoublePoint
    public let corner2: DoublePoint
    public let corner3: DoublePoint
    public let corner4: DoublePoint
}

/// Based on a version of Ramer-Douglas-Peucker
/// https://en.wikipedia.org/wiki/Ramer%E2%80%93Douglas%E2%80%93Peucker_algorithm
/// Adapted from OpenCV's implementation.
public struct RDPParameters {
    public let minPoints: Int
    
    /// Maximum allowed deviation of points, relative to the length of the diagonal.
    /// For a quadrangle with straight sides, that distance would be zero.
    public let sideErrorLimit: Double
    
    /// Maximum allowed deviation from a square aspect ratio of `1.0`.
    public let aspectRatioErrorLimit: Double
    
    public static let starter = RDPParameters(
        minPoints: 20,
        sideErrorLimit: 0.10,
        aspectRatioErrorLimit: 0.5
    )
}

internal func checkQuadrilateral(
    polyline: [DoublePoint],
    parameters: RDPParameters = .starter
) -> Quadrilateral? {
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
    var distFromCenter: OrderedDictionary<Int, Double> = [:]
    for (idx, pt) in polyline.enumerated() {
        let x2 = (pt.x - center.x) * (pt.x - center.x)
        let y2 = (pt.y - center.y) * (pt.y - center.y)
        let dist = sqrt(x2 + y2)
        distFromCenter[idx] = dist
    }
    let idxFarthestFromCenter = distFromCenter.max(by: { lhs, rhs in lhs.value < rhs.value })!.key
    
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
    var distFromLine: OrderedDictionary<Int, Double> = [:]
    for (idx, pt) in polyline.enumerated() where idx != idxFarthestFromCenter {
        let dist = pt.distance(p0: p0, p1: p1)
        distFromLine[idx] = dist
    }
    let idxFarthestFromLine = distFromLine.max(by: { lhs, rhs in lhs.value < rhs.value })!.key

    /// 5. Find the 2 extrema in distance from this line.
    /// i.e. treating the line as horizontal, find the points farthest above and below this line.
    /// These should be the remaining 2 corners.
    let corner1 = polyline[idxFarthestFromCenter]
    let corner3 = polyline[idxFarthestFromLine]
    var dispFromDiagonal: OrderedDictionary<Int, Double> = [:]
    for (idx, pt) in polyline.enumerated() {
        guard (idx != idxFarthestFromCenter) && (idx != idxFarthestFromLine) else {
            continue
        }
        let disp = pt.displacement(p0: corner1, p1: corner3)
        dispFromDiagonal[idx] = disp
    }

    let corner2Idx = dispFromDiagonal.min(by: { lhs, rhs in lhs.value < rhs.value })!.key
    let corner4Idx = dispFromDiagonal.max(by: { lhs, rhs in lhs.value < rhs.value })!.key
    let corner2 = polyline[corner2Idx]
    let corner4 = polyline[corner4Idx]

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
    
    /// Check aspect ratio is reasonable.
    let aspRatio = corner1.distance(to: corner2) / corner2.distance(to: corner3)
    let aspRatioError = abs(1.0 - aspRatio)
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
