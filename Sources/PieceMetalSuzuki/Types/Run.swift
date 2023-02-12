//
//  Run.swift
//  
//
//  Created by Secret Asian Man Dev on 12/2/23.
//

import Foundation

/// Indexes a contiguous sub-section of the array which represents a chain fragment.
/// Think of it as a snake.
// <- from to ->
//  ~~~~~~~~~~~>
//  ^           ^
//  tail        head (past the end)
///
// @metal-type
struct Run {
    /// The indices in `[start, end)` format, relative to the global buffer base.
    var oldTail: Int32
    var oldHead: Int32
    
    /// The indices in `[start, end)` format, relative to the global buffer base.
    var newTail: Int32
    var newHead: Int32
    
    /// Where the chain fragment should connect from and to.
    /// 0 indicates a closed border.
    /// 1-8 indicate directions from upwards, proceeding clockwise.
    var tailTriadFrom: ChainDirection.RawValue
    var headTriadTo: ChainDirection.RawValue

    /// An invalid value used to initialize the process.
    static let initial = Run(oldTail: -1, oldHead: -1, newTail: -1, newHead: -1, tailTriadFrom: ChainDirection.closed.rawValue, headTriadTo: ChainDirection.closed.rawValue)
    
    /// Negative values are used to indicate an invalid run that should be treated as `nil`.
    var isValid: Bool { oldHead >= 0 }
}

extension Run: CustomStringConvertible {
    var description: String {
        ""
        + "([\(oldTail), \(oldHead))->"
        +  "[\(newTail), \(newHead)), "
        + "\(ChainDirection(rawValue: tailTriadFrom)!)->\(ChainDirection(rawValue: headTriadTo)!))"
        
    }
}
