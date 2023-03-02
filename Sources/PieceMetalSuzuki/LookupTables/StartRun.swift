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
    
    public static let invalid = StartRun(tail: -1, head: -1, from: .max, to: .max)
}
