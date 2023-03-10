//
//  DoublePoint.swift
//  
//
//  Created by Secret Asian Man Dev on 21/2/23.
//

import Foundation

public struct DoublePoint: Equatable, CustomStringConvertible {
    
    public let x: Double
    public let y: Double
    
    public init(x: Double, y: Double) {
        self.x = x
        self.y = y
    }
    
    internal init(_ pt: PixelPoint) {
        self.x = Double(pt.x)
        self.y = Double(pt.y)
    }
    
    /// Source: https://en.wikipedia.org/wiki/Distance_from_a_point_to_a_line
    /// Signed distance above or below a line.
    /// Line defined by p0, p1.
    internal func displacement(p0: DoublePoint, p1: DoublePoint) -> Double {
        assert(p0 != p1)
        let a = (p1.x - p0.x) * (p0.y - self.y)
        let b = (p1.y - p0.y) * (p0.x - self.x)
        let dx2 = (p1.x - p0.x) * (p1.x - p0.x)
        let dy2 = (p1.y - p0.y) * (p1.y - p0.y)
        return (a - b) / sqrt(dx2 + dy2)
    }

    /// Absolute distance from a line.
    /// Line defined by p0, p1.
    internal func distance(p0: DoublePoint, p1: DoublePoint) -> Double {
        return abs(displacement(p0: p0, p1: p1))
    }

    internal func distance(to other: DoublePoint) -> Double {
        let dx = self.x - other.x
        let dy = self.y - other.y
        return sqrt((dx * dx) + (dy * dy))
    }
    
    public var description: String {
        /// Print to 3dp.
        let format = "%.3f"
        return "(\(String(format: format, x)), \(String(format: format, y)))"
    }
}

public struct DoubleVector {
    
    public let start: DoublePoint
    public let end: DoublePoint

    
}
