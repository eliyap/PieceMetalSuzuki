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
public struct Run: CustomStringConvertible {
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
    
    init(oldTail: Int32, oldHead: Int32, tailTriadFrom: ChainDirection.RawValue, headTriadTo: ChainDirection.RawValue) {
        self.oldTail = oldTail
        self.oldHead = oldHead
        self.newTail = -1
        self.newHead = -1
        self.tailTriadFrom = tailTriadFrom
        self.headTriadTo = headTriadTo
    }

    /// An invalid value used to initialize the process.
    static let initial = Run(oldTail: -1, oldHead: -1, tailTriadFrom: ChainDirection.closed.rawValue, headTriadTo: ChainDirection.closed.rawValue)
    
    /// Negative values are used to indicate an invalid run that should be treated as `nil`.
    var isValid: Bool { oldHead >= 0 }

    public var description: String {
        ""
        + "([\(oldTail), \(oldHead))->"
        +  "[\(newTail), \(newHead)), "
        + "\(ChainDirection(rawValue: tailTriadFrom)!)->\(ChainDirection(rawValue: headTriadTo)!))"
    }
}
