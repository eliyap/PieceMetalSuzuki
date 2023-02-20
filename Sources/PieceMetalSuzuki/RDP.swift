//
//  File.swift
//  
//
//  Created by Secret Asian Man Dev on 19/2/23.
//

import Foundation
import OrderedCollections

struct RDPParameters {
    let minPoints: Int
    let epsilon: Double
    
    static let starter = RDPParameters(
        minPoints: 20,
        epsilon: 1
    )
}

struct DoublePoint: Equatable {
    let x: Double
    let y: Double
    init(_ pt: PixelPoint) {
        self.x = Double(pt.x)
        self.y = Double(pt.y)
    }
}

/// Line defined by p0, p1.
func distance(to pt: DoublePoint, p0: DoublePoint, p1: DoublePoint) -> Double {
    assert(p0 != p1)
    let a = (p1.x - p0.x) * (p0.y - pt.y)
    let b = (p1.y - p0.y) * (p0.x - pt.x)
    let dx2 = (p1.x - p0.x) * (p1.x - p0.x)
    let dy2 = (p1.y - p0.y) * (p1.y - p0.y)
    return abs(a - b) / sqrt(dx2 + dy2)
}

func approximate(polyline: [DoublePoint], parameters: RDPParameters = .starter) -> Bool {
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
