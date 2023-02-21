//
//  File.swift
//  
//
//  Created by Secret Asian Man Dev on 19/2/23.
//

import Foundation
import OrderedCollections

public struct RDPParameters {
    let minPoints: Int
    let epsilon: Double
    
    public static let starter = RDPParameters(
        minPoints: 20,
        epsilon: 3
    )
}

public struct DoublePoint: Equatable {
    let x: Double
    let y: Double
    public init(_ pt: PixelPoint) {
        self.x = Double(pt.x)
        self.y = Double(pt.y)
    }
    public init(x: Double, y: Double) {
        self.x = x
        self.y = y
    }
}

/// Line defined by p0, p1.
func displacement(to pt: DoublePoint, p0: DoublePoint, p1: DoublePoint) -> Double {
    assert(p0 != p1)
    let a = (p1.x - p0.x) * (p0.y - pt.y)
    let b = (p1.y - p0.y) * (p0.x - pt.x)
    let dx2 = (p1.x - p0.x) * (p1.x - p0.x)
    let dy2 = (p1.y - p0.y) * (p1.y - p0.y)
    return (a - b) / sqrt(dx2 + dy2)
}

/// Line defined by p0, p1.
func distance(to pt: DoublePoint, p0: DoublePoint, p1: DoublePoint) -> Double {
    return abs(displacement(to: pt, p0: p0, p1: p1))
}

public func approximate(polyline: [DoublePoint], parameters: RDPParameters = .starter) -> Bool {
    guard polyline.count > parameters.minPoints else {
        return false
    }
    
    /// Pick 2 extreme points to start.
    let ranking: (Int, Int) -> Bool = { lhs, rhs in
        return polyline[lhs].y == polyline[rhs].y
            ? polyline[lhs].y < polyline[rhs].y
            : polyline[lhs].x < polyline[rhs].x
    }
    
    let smallest: Int = polyline.indices.min(by: ranking)!
    let largest: Int = polyline.indices.max(by: ranking)!
    let start = min(smallest, largest)
    let end = max(smallest, largest)
    
    /// Recursive polyline reduction step.
    func rdp<Coll>(indices: Coll) -> [Int] where Coll: RandomAccessCollection, Coll.Element == Int, Coll.Index == Int {
        var distances: [Coll.Element: Double] = [:]
        let p0 = polyline[indices.first!]
        let p1 = polyline[indices.last!]
        
        /// Calculate perpendicular distances for all middle points.
        for idx in indices[(indices.indices.startIndex+1)..<(indices.indices.endIndex-1)] {
            let pt = polyline[idx]
            distances[idx] = distance(to: pt, p0: p0, p1: p1)
        }
        
        if distances.values.allSatisfy({ dist in dist < parameters.epsilon }) {
            /// Base case: disregard all middle points.
            return [indices.first!, indices.last!]
        } else {
            /// Split the line at the farthest point.
            let maxIdx = distances.max(by: { lhs, rhs in lhs.value < rhs.value })!.key
            let maxIdxIdx = indices.firstIndex(of: maxIdx)!
            
            /// Recurse on both halves.
            let leftHalf = rdp(indices: indices[indices.indices.startIndex...maxIdxIdx])
            let rightHalf = rdp(indices: indices[maxIdxIdx..<indices.indices.endIndex])
            
            /// Drop duplicated center value.
            return leftHalf + rightHalf[1..<rightHalf.count]
        }
    }
    
    let leftHalf = rdp(indices: Array(start...end))
    let rightHalf = rdp(indices: Array(end..<polyline.count) + Array(0...start))
    let pointIndices = leftHalf + rightHalf[1..<rightHalf.count]
    
    return pointIndices.count < 6
}

public func checkQuadrangle(
    polyline: [DoublePoint],
    parameters: RDPParameters = .starter
) -> (DoublePoint, DoublePoint, DoublePoint, DoublePoint)? {
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
    let ptFarthestFromCenter = polyline[idxFarthestFromCenter]
    let dx = ptFarthestFromCenter.x - center.x
    let dy = ptFarthestFromCenter.y - center.y
    let p0 = DoublePoint(x: center.x - dy, y: center.y + dx)
    let p1 = DoublePoint(x: center.x + dy, y: center.y - dx)
    #if SHOW_RDP_WORK
    debugPrint("[RDP] farthest: \(farthest)")
    debugPrint("[RDP] p0: \(p0), p1: \(p1)")
    #endif

    /// 4. Find the point farthest from this line.
    var distFromLine: OrderedDictionary<Int, Double> = [:]
    for (idx, pt) in polyline.enumerated() where idx != idxFarthestFromCenter {
        let dist = distance(to: pt, p0: p0, p1: p1)
        distFromLine[idx] = dist
    }
    let idxFarthestFromLine = distFromLine.max(by: { lhs, rhs in lhs.value < rhs.value })!.key

    /// 5. Find the 2 extrema in distance from this line.
    let corner1 = polyline[idxFarthestFromCenter]
    let corner3 = polyline[idxFarthestFromLine]
    var dispFromDiagonal: OrderedDictionary<Int, Double> = [:]
    for (idx, pt) in polyline.enumerated() {
        guard (idx != idxFarthestFromCenter) && (idx != idxFarthestFromLine) else {
            continue
        }
        let disp = displacement(to: pt, p0: corner1, p1: corner3)
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
    let withinLines = polyline.allSatisfy { pt in
        if pt == corner1 || pt == corner2 || pt == corner3 || pt == corner4 {
            return true
        }
        let alongLines = false
            || (distance(to: pt, p0: corner1, p1: corner2) < parameters.epsilon)
            || (distance(to: pt, p0: corner2, p1: corner3) < parameters.epsilon)
            || (distance(to: pt, p0: corner3, p1: corner4) < parameters.epsilon)
            || (distance(to: pt, p0: corner4, p1: corner1) < parameters.epsilon)
        
        #if SHOW_RDP_WORK
        if !alongLines {
            debugPrint("[RDP] Failed due to point \(pt)")
            debugPrint("\(distance(to: pt, p0: corner1, p1: corner2))")
            debugPrint("\(distance(to: pt, p0: corner2, p1: corner3))")
            debugPrint("\(distance(to: pt, p0: corner3, p1: corner4))")
            debugPrint("\(distance(to: pt, p0: corner4, p1: corner1))")
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

    return (corner1, corner2, corner3, corner4)
}
