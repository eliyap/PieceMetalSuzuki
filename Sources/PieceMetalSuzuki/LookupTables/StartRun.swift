//
//  StartRun.swift
//  
//
//  Created by Secret Asian Man Dev on 18/2/23.
//

import Foundation

/// Represents a series of points in the pattern's core.
/// Because runs are short, we can use narrow integers.
// @metal-type
struct StartRun: Hashable, Codable, Equatable {
    /// Invalid negative values signal absence of a run.
    let tail: Int8
    let head: Int8
    
    let from: ChainDirection.RawValue
    let to: ChainDirection.RawValue
    
    public init(tail: Int8, head: Int8, from: ChainDirection.RawValue, to: ChainDirection.RawValue) {
        self.tail = tail
        self.head = head
        self.from = from
        self.to = to
    }
    
    public static let invalid = StartRun(tail: -1, head: -1, from: .max, to: .max)
}

extension StartRun {
    public var binary: UInt32 {
        /// Pack bits together.
        return UInt32.zero
            | UInt32(truncatingIfNeeded: tail) << 24
            | UInt32(truncatingIfNeeded: head) << 16
            | UInt32(truncatingIfNeeded: from) <<  8
            | UInt32(truncatingIfNeeded: to  ) <<  0
    }
    
    public init(binary: UInt32) {
        self.init(
            tail:  Int8(truncatingIfNeeded: binary >> 24),
            head:  Int8(truncatingIfNeeded: binary >> 16),
            from: UInt8(truncatingIfNeeded: binary >>  8),
            to:   UInt8(truncatingIfNeeded: binary >>  0)
        )
    }
}
