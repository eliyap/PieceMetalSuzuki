//
//  Alignment.swift
//  PieceMetalSuzuki
//
//  Created by Secret Asian Man Dev on 9/2/23.
//

import Foundation

enum ChainDirection: UInt8, Equatable {
    case closed = 0 /// Indicates a closed border.
    case up          = 1
    case topRight    = 2
    case right       = 3
    case bottomRight = 4
    case down        = 5
    case bottomLeft  = 6
    case left        = 7
    case topLeft     = 8

    var inverse : ChainDirection {
        switch self {
        case .closed:
            assert(false, "Cannot invert a closed border.")
            return .closed
        case .up:          return .down
        case .topRight:    return .bottomLeft
        case .right:       return .left
        case .bottomRight: return .topLeft
        case .down:        return .up
        case .bottomLeft:  return .topRight
        case .left:        return .right
        case .topLeft:     return .bottomRight
        }
    }
}

extension ChainDirection: CustomStringConvertible {
    var description: String {
        switch self {
        case .closed:
            return "⏺️"
        case .up:
            return "⬆️"
        case .topRight:
            return "↗️"
        case .right:
            return "➡️"
        case .bottomRight:
            return "↘️"
        case .down:
            return "⬇️"
        case .bottomLeft:
            return "↙️"
        case .left:
            return "⬅️"
        case .topLeft:
            return "↖️"
        }
    }
}

/// Indexes a contiguous sub-section of the array which represents a chain fragment.
/// Think of it as a snake.
// <- from to ->
//  ~~~~~~~~~~~>
//  ^           ^
//  tail        head (past the end)
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
