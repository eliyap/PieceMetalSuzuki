//
//  GridPosition.swift
//  
//
//  Created by Secret Asian Man Dev on 12/2/23.
//

import Foundation

/// Indicates where a `Region` is within the `Grid`.
struct GridPosition: CustomStringConvertible {
    var row: UInt32
    var col: UInt32
    var description: String {
        return "gr\(row)gc\(col)"
    }
}
