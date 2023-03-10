//
//  File.swift
//  
//
//  Created by Secret Asian Man Dev on 10/3/23.
//

import Foundation

public protocol Tolerance {
    associatedtype Value: FloatingPoint
    var target: Value { get }
    var maxError: Value  { get }
    func accepts(_ value: Value) -> Bool
}


public struct ProportionalTolerance<Value: FloatingPoint>: Tolerance {
    public let target: Value
    
    /// Allowed proportional deviation from the `target`.
    /// e.g. 0.1 allows values within 90% to 110% of the target.
    public let maxError: Value
    
    public func accepts(_ value: Value) -> Bool {
        let ratio = value / target
        let proportionError = abs(ratio - 1)
        return proportionError < maxError
    }
}

public struct AbsoluteTolerance<Value: FloatingPoint>: Tolerance {
    public let target: Value
    
    /// Allowed proportional deviation from the `target`.
    /// e.g. 0.1 allows values within 90% to 110% of the target.
    public let maxError: Value
    
    public func accepts(_ value: Value) -> Bool {
        let absoluteError = abs(value - target)
        return absoluteError < maxError
    }
}

public extension FloatingPoint {
    func isWithin<ToleranceType: Tolerance>(_ tolerance: ToleranceType) -> Bool where ToleranceType.Value == Self {
        tolerance.accepts(self)
    }
}
