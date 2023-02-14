//
//  PixelPoint.swift
//  PieceMetalSuzuki
//
//  Created by Secret Asian Man Dev on 12/2/23.
//

import Foundation

// @metal-type
struct PixelPoint: Equatable {
    /// Corresponds to `thread_position_in_grid` with type `uint2`.
    /// https://developer.apple.com/documentation/metal/mtlattributeformat/uint2
    /// > Two unsigned 32-bit values.
    let x: UInt32
    let y: UInt32

    subscript(_ direction: ChainDirection) -> PixelPoint {
        switch direction {
        case .closed:
            assert(false, "Cannot index a closed border.")
            return self
        case .up:          return PixelPoint(x: x,     y: y - 1)
        case .topRight:    return PixelPoint(x: x + 1, y: y - 1)
        case .right:       return PixelPoint(x: x + 1, y: y    )
        case .bottomRight: return PixelPoint(x: x + 1, y: y + 1)
        case .down:        return PixelPoint(x: x,     y: y + 1)
        case .bottomLeft:  return PixelPoint(x: x - 1, y: y + 1)
        case .left:        return PixelPoint(x: x - 1, y: y    )
        case .topLeft:     return PixelPoint(x: x - 1, y: y - 1)
        }
    }
    
    subscript(_ direction: ChainDirection.RawValue) -> PixelPoint {
        switch direction {
        case ChainDirection.closed.rawValue:
            assert(false, "Cannot index a closed border.")
            return self
        case ChainDirection.up.rawValue:          return PixelPoint(x: x,     y: y - 1)
        case ChainDirection.topRight.rawValue:    return PixelPoint(x: x + 1, y: y - 1)
        case ChainDirection.right.rawValue:       return PixelPoint(x: x + 1, y: y    )
        case ChainDirection.bottomRight.rawValue: return PixelPoint(x: x + 1, y: y + 1)
        case ChainDirection.down.rawValue:        return PixelPoint(x: x,     y: y + 1)
        case ChainDirection.bottomLeft.rawValue:  return PixelPoint(x: x - 1, y: y + 1)
        case ChainDirection.left.rawValue:        return PixelPoint(x: x - 1, y: y    )
        case ChainDirection.topLeft.rawValue:     return PixelPoint(x: x - 1, y: y - 1)
        default:
            assertionFailure("Invalid direction")
            return self
        }
    }

    /// An invalid point, since the frame should never be analyzed.
    static let zero = PixelPoint(x: .zero, y: .zero)
}

extension PixelPoint: CustomStringConvertible {
    var description: String { "r\(y)c\(x)"}
}
