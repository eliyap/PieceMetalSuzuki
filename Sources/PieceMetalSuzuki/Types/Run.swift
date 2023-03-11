//  Run.swift
//  Created by Secret Asian Man Dev on 12/2/23.

import Foundation

/// Conceptually, this represents metadata for a "border fragment", a contiguous sub-section of the `Point` buffer.
/// Think of it as a snake.
/// ```
/// <- from to ->
/// ~~~~~~~~~~~~>
/// ^           ^
/// tail        head (past the end)
/// ```
/// Each `~` is a `Point` in the buffer.
/// While combining `Regions`, we care about the first and last points ("head" and "tail"),
/// which help us combine the `Run` with other `Run`s until a complete border is formed – a closed `Run`.
// @metal-type
internal struct Run: CustomStringConvertible {
    /// The indices in `[start, end)` format, relative to the global buffer base.
    /// Uses signed values. This allows negative indices to indicate an invalid `Run`.
    /// When combining regions, points are copied from the `old~` offsets to their `new~` offsets.
    var oldTail: Int32
    var oldHead: Int32
    var newTail: Int32
    var newHead: Int32
    
    /// The direction in which the border fragment connects from and to.
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
    
    /// A short-hand for lookup tables to use.
    init(t: Int32, h: Int32, from: ChainDirection.RawValue, to: ChainDirection.RawValue) {
        self.init(oldTail: t, oldHead: h, tailTriadFrom: from, headTriadTo: to)
    }

    /// An invalid value used to initialize the process.
    static let invalid = Run(oldTail: -1, oldHead: -1, tailTriadFrom: ChainDirection.closed.rawValue, headTriadTo: ChainDirection.closed.rawValue)
    
    /// Negative values are used to indicate an invalid run that should be treated as `nil`.
    var isValid: Bool { oldHead >= 0 }

    public var description: String {
        ""
        + "([\(oldTail), \(oldHead))->"
        +  "[\(newTail), \(newHead)), "
        + "\(ChainDirection(rawValue: tailTriadFrom)!)->\(ChainDirection(rawValue: headTriadTo)!))"
    }
}
