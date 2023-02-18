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
struct StartPoint: Hashable, Codable {
    let x: UInt8
    let y: UInt8
    
    public static let invalid = StartPoint(x: .max, y: .max)
}
