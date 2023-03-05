//
//  StartPoint.swift
//  
//
//  Created by Secret Asian Man Dev on 18/2/23.
//

import Foundation

/// Represents a point within the pattern's core.
/// Because patterns are small, we can use narrow integers.
// @metal-type
struct StartPoint: Hashable, Codable, Equatable {
    let x: UInt8
    let y: UInt8
    
    public static let invalid = StartPoint(x: .max, y: .max)
}

extension StartPoint: ByteConvertible {
    
    static var byteCount: Int = 2
    
    public var data: Data {
        /// Pack bits together.
        return Data([x, y])
    }
    
    public init(data: Data) {
        self.init(
            x: data[data.indices.lowerBound + 0],
            y: data[data.indices.lowerBound + 1]
        )
    }
}
