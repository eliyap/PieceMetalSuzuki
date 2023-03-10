//
//  ChainDirection.swift
//  PieceMetalSuzuki
//
//  Created by Secret Asian Man Dev on 9/2/23.
//

import Foundation

enum ChainDirection: UInt8, Equatable {
    case closed      = 0 /// Indicates a closed border.
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
