//
//  RunLUT.swift
//  
//
//  Created by Secret Asian Man Dev on 14/2/23.
//

import Foundation
import Metal

extension Run {
    
    static var LUTBuffer: Buffer<Run>? = {
        let device = MTLCreateSystemDefaultDevice()!
        guard let buffer = Buffer<Run>.init(device: device, count: LUT.count) else {
            assertionFailure("Failed to create LUT buffer")
            return nil
        }
        memcpy(buffer.array, LUT, MemoryLayout<Run>.stride * LUT.count)
        return buffer
    }()
    
    static let LUT: [Run] = [
        // 000
        // 0 0
        // 000
        Run.invalid,
        Run.invalid,
        Run.invalid,
        Run.invalid,

        // 100
        // 0 0
        // 000
        Run(t: 0, h: 1, from: ChainDirection.topLeft.rawValue, to: ChainDirection.topLeft.rawValue),
        Run.invalid,
        Run.invalid,
        Run.invalid,

        // 010
        // 0 0
        // 000
        Run(t: 0, h: 1, from: ChainDirection.up.rawValue, to: ChainDirection.up.rawValue),
        Run.invalid,
        Run.invalid,
        Run.invalid,

        // 110
        // 0 0
        // 000
        Run(t: 0, h: 1, from: ChainDirection.up.rawValue, to: ChainDirection.topLeft.rawValue),
        Run.invalid,
        Run.invalid,
        Run.invalid,

        // 001
        // 0 0
        // 000
        Run(t: 0, h: 1, from: ChainDirection.topRight.rawValue, to: ChainDirection.topRight.rawValue),
        Run.invalid,
        Run.invalid,
        Run.invalid,

        // 101
        // 0 0
        // 000
        Run(t: 0, h: 1, from: ChainDirection.topRight.rawValue, to: ChainDirection.topLeft.rawValue),
        Run(t: 0, h: 1, from: ChainDirection.topLeft.rawValue, to: ChainDirection.topRight.rawValue),
        Run.invalid,
        Run.invalid,

        // 011
        // 0 0
        // 000
        Run(t: 0, h: 1, from: ChainDirection.topRight.rawValue, to: ChainDirection.up.rawValue),
        Run.invalid,
        Run.invalid,
        Run.invalid,

        // 111
        // 0 0
        // 000
        Run(t: 0, h: 1, from: ChainDirection.topRight.rawValue, to: ChainDirection.topLeft.rawValue),
        Run.invalid,
        Run.invalid,
        Run.invalid,

        // 000
        // 1 0
        // 000
        Run(t: 0, h: 1, from: ChainDirection.left.rawValue, to: ChainDirection.left.rawValue),
        Run.invalid,
        Run.invalid,
        Run.invalid,

        // 100
        // 1 0
        // 000
        Run(t: 0, h: 1, from: ChainDirection.topLeft.rawValue, to: ChainDirection.left.rawValue),
        Run.invalid,
        Run.invalid,
        Run.invalid,

        // 010
        // 1 0
        // 000
        Run(t: 0, h: 1, from: ChainDirection.up.rawValue, to: ChainDirection.left.rawValue),
        Run.invalid,
        Run.invalid,
        Run.invalid,

        // 110
        // 1 0
        // 000
        Run(t: 0, h: 1, from: ChainDirection.up.rawValue, to: ChainDirection.left.rawValue),
        Run.invalid,
        Run.invalid,
        Run.invalid,

        // 001
        // 1 0
        // 000
        Run(t: 0, h: 1, from: ChainDirection.topRight.rawValue, to: ChainDirection.left.rawValue),
        Run(t: 0, h: 1, from: ChainDirection.left.rawValue, to: ChainDirection.topRight.rawValue),
        Run.invalid,
        Run.invalid,

        // 101
        // 1 0
        // 000
        Run(t: 0, h: 1, from: ChainDirection.topRight.rawValue, to: ChainDirection.left.rawValue),
        Run(t: 0, h: 1, from: ChainDirection.topLeft.rawValue, to: ChainDirection.topRight.rawValue),
        Run.invalid,
        Run.invalid,

        // 011
        // 1 0
        // 000
        Run(t: 0, h: 1, from: ChainDirection.topRight.rawValue, to: ChainDirection.left.rawValue),
        Run.invalid,
        Run.invalid,
        Run.invalid,

        // 111
        // 1 0
        // 000
        Run(t: 0, h: 1, from: ChainDirection.topRight.rawValue, to: ChainDirection.left.rawValue),
        Run.invalid,
        Run.invalid,
        Run.invalid,

        // 000
        // 0 1
        // 000
        Run(t: 0, h: 1, from: ChainDirection.right.rawValue, to: ChainDirection.right.rawValue),
        Run.invalid,
        Run.invalid,
        Run.invalid,

        // 100
        // 0 1
        // 000
        Run(t: 0, h: 1, from: ChainDirection.right.rawValue, to: ChainDirection.topLeft.rawValue),
        Run(t: 0, h: 1, from: ChainDirection.topLeft.rawValue, to: ChainDirection.right.rawValue),
        Run.invalid,
        Run.invalid,

        // 010
        // 0 1
        // 000
        Run(t: 0, h: 1, from: ChainDirection.right.rawValue, to: ChainDirection.up.rawValue),
        Run.invalid,
        Run.invalid,
        Run.invalid,

        // 110
        // 0 1
        // 000
        Run(t: 0, h: 1, from: ChainDirection.right.rawValue, to: ChainDirection.topLeft.rawValue),
        Run.invalid,
        Run.invalid,
        Run.invalid,

        // 001
        // 0 1
        // 000
        Run(t: 0, h: 1, from: ChainDirection.right.rawValue, to: ChainDirection.topRight.rawValue),
        Run.invalid,
        Run.invalid,
        Run.invalid,

        // 101
        // 0 1
        // 000
        Run(t: 0, h: 1, from: ChainDirection.right.rawValue, to: ChainDirection.topLeft.rawValue),
        Run(t: 0, h: 1, from: ChainDirection.topLeft.rawValue, to: ChainDirection.topRight.rawValue),
        Run.invalid,
        Run.invalid,

        // 011
        // 0 1
        // 000
        Run(t: 0, h: 1, from: ChainDirection.right.rawValue, to: ChainDirection.up.rawValue),
        Run.invalid,
        Run.invalid,
        Run.invalid,

        // 111
        // 0 1
        // 000
        Run(t: 0, h: 1, from: ChainDirection.right.rawValue, to: ChainDirection.topLeft.rawValue),
        Run.invalid,
        Run.invalid,
        Run.invalid,

        // 000
        // 1 1
        // 000
        Run(t: 0, h: 1, from: ChainDirection.right.rawValue, to: ChainDirection.left.rawValue),
        Run(t: 0, h: 1, from: ChainDirection.left.rawValue, to: ChainDirection.right.rawValue),
        Run.invalid,
        Run.invalid,

        // 100
        // 1 1
        // 000
        Run(t: 0, h: 1, from: ChainDirection.right.rawValue, to: ChainDirection.left.rawValue),
        Run(t: 0, h: 1, from: ChainDirection.topLeft.rawValue, to: ChainDirection.right.rawValue),
        Run.invalid,
        Run.invalid,

        // 010
        // 1 1
        // 000
        Run(t: 0, h: 1, from: ChainDirection.right.rawValue, to: ChainDirection.left.rawValue),
        Run.invalid,
        Run.invalid,
        Run.invalid,

        // 110
        // 1 1
        // 000
        Run(t: 0, h: 1, from: ChainDirection.right.rawValue, to: ChainDirection.left.rawValue),
        Run.invalid,
        Run.invalid,
        Run.invalid,

        // 001
        // 1 1
        // 000
        Run(t: 0, h: 1, from: ChainDirection.right.rawValue, to: ChainDirection.left.rawValue),
        Run(t: 0, h: 1, from: ChainDirection.left.rawValue, to: ChainDirection.topRight.rawValue),
        Run.invalid,
        Run.invalid,

        // 101
        // 1 1
        // 000
        Run(t: 0, h: 1, from: ChainDirection.right.rawValue, to: ChainDirection.left.rawValue),
        Run(t: 0, h: 1, from: ChainDirection.topLeft.rawValue, to: ChainDirection.topRight.rawValue),
        Run.invalid,
        Run.invalid,

        // 011
        // 1 1
        // 000
        Run(t: 0, h: 1, from: ChainDirection.right.rawValue, to: ChainDirection.left.rawValue),
        Run.invalid,
        Run.invalid,
        Run.invalid,

        // 111
        // 1 1
        // 000
        Run(t: 0, h: 1, from: ChainDirection.right.rawValue, to: ChainDirection.left.rawValue),
        Run.invalid,
        Run.invalid,
        Run.invalid,

        // 000
        // 0 0
        // 100
        Run(t: 0, h: 1, from: ChainDirection.bottomLeft.rawValue, to: ChainDirection.bottomLeft.rawValue),
        Run.invalid,
        Run.invalid,
        Run.invalid,

        // 100
        // 0 0
        // 100
        Run(t: 0, h: 1, from: ChainDirection.bottomLeft.rawValue, to: ChainDirection.topLeft.rawValue),
        Run(t: 0, h: 1, from: ChainDirection.topLeft.rawValue, to: ChainDirection.bottomLeft.rawValue),
        Run.invalid,
        Run.invalid,

        // 010
        // 0 0
        // 100
        Run(t: 0, h: 1, from: ChainDirection.bottomLeft.rawValue, to: ChainDirection.up.rawValue),
        Run(t: 0, h: 1, from: ChainDirection.up.rawValue, to: ChainDirection.bottomLeft.rawValue),
        Run.invalid,
        Run.invalid,

        // 110
        // 0 0
        // 100
        Run(t: 0, h: 1, from: ChainDirection.bottomLeft.rawValue, to: ChainDirection.topLeft.rawValue),
        Run(t: 0, h: 1, from: ChainDirection.up.rawValue, to: ChainDirection.bottomLeft.rawValue),
        Run.invalid,
        Run.invalid,

        // 001
        // 0 0
        // 100
        Run(t: 0, h: 1, from: ChainDirection.topRight.rawValue, to: ChainDirection.bottomLeft.rawValue),
        Run(t: 0, h: 1, from: ChainDirection.bottomLeft.rawValue, to: ChainDirection.topRight.rawValue),
        Run.invalid,
        Run.invalid,

        // 101
        // 0 0
        // 100
        Run(t: 0, h: 1, from: ChainDirection.topRight.rawValue, to: ChainDirection.bottomLeft.rawValue),
        Run(t: 0, h: 1, from: ChainDirection.bottomLeft.rawValue, to: ChainDirection.topLeft.rawValue),
        Run(t: 0, h: 1, from: ChainDirection.topLeft.rawValue, to: ChainDirection.topRight.rawValue),
        Run.invalid,

        // 011
        // 0 0
        // 100
        Run(t: 0, h: 1, from: ChainDirection.topRight.rawValue, to: ChainDirection.bottomLeft.rawValue),
        Run(t: 0, h: 1, from: ChainDirection.bottomLeft.rawValue, to: ChainDirection.up.rawValue),
        Run.invalid,
        Run.invalid,

        // 111
        // 0 0
        // 100
        Run(t: 0, h: 1, from: ChainDirection.topRight.rawValue, to: ChainDirection.bottomLeft.rawValue),
        Run(t: 0, h: 1, from: ChainDirection.bottomLeft.rawValue, to: ChainDirection.topLeft.rawValue),
        Run.invalid,
        Run.invalid,

        // 000
        // 1 0
        // 100
        Run(t: 0, h: 1, from: ChainDirection.left.rawValue, to: ChainDirection.bottomLeft.rawValue),
        Run.invalid,
        Run.invalid,
        Run.invalid,

        // 100
        // 1 0
        // 100
        Run(t: 0, h: 1, from: ChainDirection.topLeft.rawValue, to: ChainDirection.bottomLeft.rawValue),
        Run.invalid,
        Run.invalid,
        Run.invalid,

        // 010
        // 1 0
        // 100
        Run(t: 0, h: 1, from: ChainDirection.up.rawValue, to: ChainDirection.bottomLeft.rawValue),
        Run.invalid,
        Run.invalid,
        Run.invalid,

        // 110
        // 1 0
        // 100
        Run(t: 0, h: 1, from: ChainDirection.up.rawValue, to: ChainDirection.bottomLeft.rawValue),
        Run.invalid,
        Run.invalid,
        Run.invalid,

        // 001
        // 1 0
        // 100
        Run(t: 0, h: 1, from: ChainDirection.topRight.rawValue, to: ChainDirection.bottomLeft.rawValue),
        Run(t: 0, h: 1, from: ChainDirection.left.rawValue, to: ChainDirection.topRight.rawValue),
        Run.invalid,
        Run.invalid,

        // 101
        // 1 0
        // 100
        Run(t: 0, h: 1, from: ChainDirection.topRight.rawValue, to: ChainDirection.bottomLeft.rawValue),
        Run(t: 0, h: 1, from: ChainDirection.topLeft.rawValue, to: ChainDirection.topRight.rawValue),
        Run.invalid,
        Run.invalid,

        // 011
        // 1 0
        // 100
        Run(t: 0, h: 1, from: ChainDirection.topRight.rawValue, to: ChainDirection.bottomLeft.rawValue),
        Run.invalid,
        Run.invalid,
        Run.invalid,

        // 111
        // 1 0
        // 100
        Run(t: 0, h: 1, from: ChainDirection.topRight.rawValue, to: ChainDirection.bottomLeft.rawValue),
        Run.invalid,
        Run.invalid,
        Run.invalid,

        // 000
        // 0 1
        // 100
        Run(t: 0, h: 1, from: ChainDirection.right.rawValue, to: ChainDirection.bottomLeft.rawValue),
        Run(t: 0, h: 1, from: ChainDirection.bottomLeft.rawValue, to: ChainDirection.right.rawValue),
        Run.invalid,
        Run.invalid,

        // 100
        // 0 1
        // 100
        Run(t: 0, h: 1, from: ChainDirection.right.rawValue, to: ChainDirection.bottomLeft.rawValue),
        Run(t: 0, h: 1, from: ChainDirection.bottomLeft.rawValue, to: ChainDirection.topLeft.rawValue),
        Run(t: 0, h: 1, from: ChainDirection.topLeft.rawValue, to: ChainDirection.right.rawValue),
        Run.invalid,

        // 010
        // 0 1
        // 100
        Run(t: 0, h: 1, from: ChainDirection.right.rawValue, to: ChainDirection.bottomLeft.rawValue),
        Run(t: 0, h: 1, from: ChainDirection.bottomLeft.rawValue, to: ChainDirection.up.rawValue),
        Run.invalid,
        Run.invalid,

        // 110
        // 0 1
        // 100
        Run(t: 0, h: 1, from: ChainDirection.right.rawValue, to: ChainDirection.bottomLeft.rawValue),
        Run(t: 0, h: 1, from: ChainDirection.bottomLeft.rawValue, to: ChainDirection.topLeft.rawValue),
        Run.invalid,
        Run.invalid,

        // 001
        // 0 1
        // 100
        Run(t: 0, h: 1, from: ChainDirection.right.rawValue, to: ChainDirection.bottomLeft.rawValue),
        Run(t: 0, h: 1, from: ChainDirection.bottomLeft.rawValue, to: ChainDirection.topRight.rawValue),
        Run.invalid,
        Run.invalid,

        // 101
        // 0 1
        // 100
        Run(t: 0, h: 1, from: ChainDirection.right.rawValue, to: ChainDirection.bottomLeft.rawValue),
        Run(t: 0, h: 1, from: ChainDirection.bottomLeft.rawValue, to: ChainDirection.topLeft.rawValue),
        Run(t: 0, h: 1, from: ChainDirection.topLeft.rawValue, to: ChainDirection.topRight.rawValue),
        Run.invalid,

        // 011
        // 0 1
        // 100
        Run(t: 0, h: 1, from: ChainDirection.right.rawValue, to: ChainDirection.bottomLeft.rawValue),
        Run(t: 0, h: 1, from: ChainDirection.bottomLeft.rawValue, to: ChainDirection.up.rawValue),
        Run.invalid,
        Run.invalid,

        // 111
        // 0 1
        // 100
        Run(t: 0, h: 1, from: ChainDirection.right.rawValue, to: ChainDirection.bottomLeft.rawValue),
        Run(t: 0, h: 1, from: ChainDirection.bottomLeft.rawValue, to: ChainDirection.topLeft.rawValue),
        Run.invalid,
        Run.invalid,

        // 000
        // 1 1
        // 100
        Run(t: 0, h: 1, from: ChainDirection.right.rawValue, to: ChainDirection.bottomLeft.rawValue),
        Run(t: 0, h: 1, from: ChainDirection.left.rawValue, to: ChainDirection.right.rawValue),
        Run.invalid,
        Run.invalid,

        // 100
        // 1 1
        // 100
        Run(t: 0, h: 1, from: ChainDirection.right.rawValue, to: ChainDirection.bottomLeft.rawValue),
        Run(t: 0, h: 1, from: ChainDirection.topLeft.rawValue, to: ChainDirection.right.rawValue),
        Run.invalid,
        Run.invalid,

        // 010
        // 1 1
        // 100
        Run(t: 0, h: 1, from: ChainDirection.right.rawValue, to: ChainDirection.bottomLeft.rawValue),
        Run.invalid,
        Run.invalid,
        Run.invalid,

        // 110
        // 1 1
        // 100
        Run(t: 0, h: 1, from: ChainDirection.right.rawValue, to: ChainDirection.bottomLeft.rawValue),
        Run.invalid,
        Run.invalid,
        Run.invalid,

        // 001
        // 1 1
        // 100
        Run(t: 0, h: 1, from: ChainDirection.right.rawValue, to: ChainDirection.bottomLeft.rawValue),
        Run(t: 0, h: 1, from: ChainDirection.left.rawValue, to: ChainDirection.topRight.rawValue),
        Run.invalid,
        Run.invalid,

        // 101
        // 1 1
        // 100
        Run(t: 0, h: 1, from: ChainDirection.right.rawValue, to: ChainDirection.bottomLeft.rawValue),
        Run(t: 0, h: 1, from: ChainDirection.topLeft.rawValue, to: ChainDirection.topRight.rawValue),
        Run.invalid,
        Run.invalid,

        // 011
        // 1 1
        // 100
        Run(t: 0, h: 1, from: ChainDirection.right.rawValue, to: ChainDirection.bottomLeft.rawValue),
        Run.invalid,
        Run.invalid,
        Run.invalid,

        // 111
        // 1 1
        // 100
        Run(t: 0, h: 1, from: ChainDirection.right.rawValue, to: ChainDirection.bottomLeft.rawValue),
        Run.invalid,
        Run.invalid,
        Run.invalid,

        // 000
        // 0 0
        // 010
        Run(t: 0, h: 1, from: ChainDirection.down.rawValue, to: ChainDirection.down.rawValue),
        Run.invalid,
        Run.invalid,
        Run.invalid,

        // 100
        // 0 0
        // 010
        Run(t: 0, h: 1, from: ChainDirection.down.rawValue, to: ChainDirection.topLeft.rawValue),
        Run(t: 0, h: 1, from: ChainDirection.topLeft.rawValue, to: ChainDirection.down.rawValue),
        Run.invalid,
        Run.invalid,

        // 010
        // 0 0
        // 010
        Run(t: 0, h: 1, from: ChainDirection.down.rawValue, to: ChainDirection.up.rawValue),
        Run(t: 0, h: 1, from: ChainDirection.up.rawValue, to: ChainDirection.down.rawValue),
        Run.invalid,
        Run.invalid,

        // 110
        // 0 0
        // 010
        Run(t: 0, h: 1, from: ChainDirection.down.rawValue, to: ChainDirection.topLeft.rawValue),
        Run(t: 0, h: 1, from: ChainDirection.up.rawValue, to: ChainDirection.down.rawValue),
        Run.invalid,
        Run.invalid,

        // 001
        // 0 0
        // 010
        Run(t: 0, h: 1, from: ChainDirection.topRight.rawValue, to: ChainDirection.down.rawValue),
        Run(t: 0, h: 1, from: ChainDirection.down.rawValue, to: ChainDirection.topRight.rawValue),
        Run.invalid,
        Run.invalid,

        // 101
        // 0 0
        // 010
        Run(t: 0, h: 1, from: ChainDirection.topRight.rawValue, to: ChainDirection.down.rawValue),
        Run(t: 0, h: 1, from: ChainDirection.down.rawValue, to: ChainDirection.topLeft.rawValue),
        Run(t: 0, h: 1, from: ChainDirection.topLeft.rawValue, to: ChainDirection.topRight.rawValue),
        Run.invalid,

        // 011
        // 0 0
        // 010
        Run(t: 0, h: 1, from: ChainDirection.topRight.rawValue, to: ChainDirection.down.rawValue),
        Run(t: 0, h: 1, from: ChainDirection.down.rawValue, to: ChainDirection.up.rawValue),
        Run.invalid,
        Run.invalid,

        // 111
        // 0 0
        // 010
        Run(t: 0, h: 1, from: ChainDirection.topRight.rawValue, to: ChainDirection.down.rawValue),
        Run(t: 0, h: 1, from: ChainDirection.down.rawValue, to: ChainDirection.topLeft.rawValue),
        Run.invalid,
        Run.invalid,

        // 000
        // 1 0
        // 010
        Run(t: 0, h: 1, from: ChainDirection.left.rawValue, to: ChainDirection.down.rawValue),
        Run.invalid,
        Run.invalid,
        Run.invalid,

        // 100
        // 1 0
        // 010
        Run(t: 0, h: 1, from: ChainDirection.topLeft.rawValue, to: ChainDirection.down.rawValue),
        Run.invalid,
        Run.invalid,
        Run.invalid,

        // 010
        // 1 0
        // 010
        Run(t: 0, h: 1, from: ChainDirection.up.rawValue, to: ChainDirection.down.rawValue),
        Run.invalid,
        Run.invalid,
        Run.invalid,

        // 110
        // 1 0
        // 010
        Run(t: 0, h: 1, from: ChainDirection.up.rawValue, to: ChainDirection.down.rawValue),
        Run.invalid,
        Run.invalid,
        Run.invalid,

        // 001
        // 1 0
        // 010
        Run(t: 0, h: 1, from: ChainDirection.topRight.rawValue, to: ChainDirection.down.rawValue),
        Run(t: 0, h: 1, from: ChainDirection.left.rawValue, to: ChainDirection.topRight.rawValue),
        Run.invalid,
        Run.invalid,

        // 101
        // 1 0
        // 010
        Run(t: 0, h: 1, from: ChainDirection.topRight.rawValue, to: ChainDirection.down.rawValue),
        Run(t: 0, h: 1, from: ChainDirection.topLeft.rawValue, to: ChainDirection.topRight.rawValue),
        Run.invalid,
        Run.invalid,

        // 011
        // 1 0
        // 010
        Run(t: 0, h: 1, from: ChainDirection.topRight.rawValue, to: ChainDirection.down.rawValue),
        Run.invalid,
        Run.invalid,
        Run.invalid,

        // 111
        // 1 0
        // 010
        Run(t: 0, h: 1, from: ChainDirection.topRight.rawValue, to: ChainDirection.down.rawValue),
        Run.invalid,
        Run.invalid,
        Run.invalid,

        // 000
        // 0 1
        // 010
        Run(t: 0, h: 1, from: ChainDirection.down.rawValue, to: ChainDirection.right.rawValue),
        Run.invalid,
        Run.invalid,
        Run.invalid,

        // 100
        // 0 1
        // 010
        Run(t: 0, h: 1, from: ChainDirection.down.rawValue, to: ChainDirection.topLeft.rawValue),
        Run(t: 0, h: 1, from: ChainDirection.topLeft.rawValue, to: ChainDirection.right.rawValue),
        Run.invalid,
        Run.invalid,

        // 010
        // 0 1
        // 010
        Run(t: 0, h: 1, from: ChainDirection.down.rawValue, to: ChainDirection.up.rawValue),
        Run.invalid,
        Run.invalid,
        Run.invalid,

        // 110
        // 0 1
        // 010
        Run(t: 0, h: 1, from: ChainDirection.down.rawValue, to: ChainDirection.topLeft.rawValue),
        Run.invalid,
        Run.invalid,
        Run.invalid,

        // 001
        // 0 1
        // 010
        Run(t: 0, h: 1, from: ChainDirection.down.rawValue, to: ChainDirection.topRight.rawValue),
        Run.invalid,
        Run.invalid,
        Run.invalid,

        // 101
        // 0 1
        // 010
        Run(t: 0, h: 1, from: ChainDirection.down.rawValue, to: ChainDirection.topLeft.rawValue),
        Run(t: 0, h: 1, from: ChainDirection.topLeft.rawValue, to: ChainDirection.topRight.rawValue),
        Run.invalid,
        Run.invalid,

        // 011
        // 0 1
        // 010
        Run(t: 0, h: 1, from: ChainDirection.down.rawValue, to: ChainDirection.up.rawValue),
        Run.invalid,
        Run.invalid,
        Run.invalid,

        // 111
        // 0 1
        // 010
        Run(t: 0, h: 1, from: ChainDirection.down.rawValue, to: ChainDirection.topLeft.rawValue),
        Run.invalid,
        Run.invalid,
        Run.invalid,

        // 000
        // 1 1
        // 010
        Run(t: 0, h: 1, from: ChainDirection.left.rawValue, to: ChainDirection.right.rawValue),
        Run.invalid,
        Run.invalid,
        Run.invalid,

        // 100
        // 1 1
        // 010
        Run(t: 0, h: 1, from: ChainDirection.topLeft.rawValue, to: ChainDirection.right.rawValue),
        Run.invalid,
        Run.invalid,
        Run.invalid,

        // 010
        // 1 1
        // 010
        Run.invalid,
        Run.invalid,
        Run.invalid,
        Run.invalid,

        // 110
        // 1 1
        // 010
        Run.invalid,
        Run.invalid,
        Run.invalid,
        Run.invalid,

        // 001
        // 1 1
        // 010
        Run(t: 0, h: 1, from: ChainDirection.left.rawValue, to: ChainDirection.topRight.rawValue),
        Run.invalid,
        Run.invalid,
        Run.invalid,

        // 101
        // 1 1
        // 010
        Run(t: 0, h: 1, from: ChainDirection.topLeft.rawValue, to: ChainDirection.topRight.rawValue),
        Run.invalid,
        Run.invalid,
        Run.invalid,

        // 011
        // 1 1
        // 010
        Run.invalid,
        Run.invalid,
        Run.invalid,
        Run.invalid,

        // 111
        // 1 1
        // 010
        Run.invalid,
        Run.invalid,
        Run.invalid,
        Run.invalid,

        // 000
        // 0 0
        // 110
        Run(t: 0, h: 1, from: ChainDirection.bottomLeft.rawValue, to: ChainDirection.down.rawValue),
        Run.invalid,
        Run.invalid,
        Run.invalid,

        // 100
        // 0 0
        // 110
        Run(t: 0, h: 1, from: ChainDirection.bottomLeft.rawValue, to: ChainDirection.topLeft.rawValue),
        Run(t: 0, h: 1, from: ChainDirection.topLeft.rawValue, to: ChainDirection.down.rawValue),
        Run.invalid,
        Run.invalid,

        // 010
        // 0 0
        // 110
        Run(t: 0, h: 1, from: ChainDirection.bottomLeft.rawValue, to: ChainDirection.up.rawValue),
        Run(t: 0, h: 1, from: ChainDirection.up.rawValue, to: ChainDirection.down.rawValue),
        Run.invalid,
        Run.invalid,

        // 110
        // 0 0
        // 110
        Run(t: 0, h: 1, from: ChainDirection.bottomLeft.rawValue, to: ChainDirection.topLeft.rawValue),
        Run(t: 0, h: 1, from: ChainDirection.up.rawValue, to: ChainDirection.down.rawValue),
        Run.invalid,
        Run.invalid,

        // 001
        // 0 0
        // 110
        Run(t: 0, h: 1, from: ChainDirection.topRight.rawValue, to: ChainDirection.down.rawValue),
        Run(t: 0, h: 1, from: ChainDirection.bottomLeft.rawValue, to: ChainDirection.topRight.rawValue),
        Run.invalid,
        Run.invalid,

        // 101
        // 0 0
        // 110
        Run(t: 0, h: 1, from: ChainDirection.topRight.rawValue, to: ChainDirection.down.rawValue),
        Run(t: 0, h: 1, from: ChainDirection.bottomLeft.rawValue, to: ChainDirection.topLeft.rawValue),
        Run(t: 0, h: 1, from: ChainDirection.topLeft.rawValue, to: ChainDirection.topRight.rawValue),
        Run.invalid,

        // 011
        // 0 0
        // 110
        Run(t: 0, h: 1, from: ChainDirection.topRight.rawValue, to: ChainDirection.down.rawValue),
        Run(t: 0, h: 1, from: ChainDirection.bottomLeft.rawValue, to: ChainDirection.up.rawValue),
        Run.invalid,
        Run.invalid,

        // 111
        // 0 0
        // 110
        Run(t: 0, h: 1, from: ChainDirection.topRight.rawValue, to: ChainDirection.down.rawValue),
        Run(t: 0, h: 1, from: ChainDirection.bottomLeft.rawValue, to: ChainDirection.topLeft.rawValue),
        Run.invalid,
        Run.invalid,

        // 000
        // 1 0
        // 110
        Run(t: 0, h: 1, from: ChainDirection.left.rawValue, to: ChainDirection.down.rawValue),
        Run.invalid,
        Run.invalid,
        Run.invalid,

        // 100
        // 1 0
        // 110
        Run(t: 0, h: 1, from: ChainDirection.topLeft.rawValue, to: ChainDirection.down.rawValue),
        Run.invalid,
        Run.invalid,
        Run.invalid,

        // 010
        // 1 0
        // 110
        Run(t: 0, h: 1, from: ChainDirection.up.rawValue, to: ChainDirection.down.rawValue),
        Run.invalid,
        Run.invalid,
        Run.invalid,

        // 110
        // 1 0
        // 110
        Run(t: 0, h: 1, from: ChainDirection.up.rawValue, to: ChainDirection.down.rawValue),
        Run.invalid,
        Run.invalid,
        Run.invalid,

        // 001
        // 1 0
        // 110
        Run(t: 0, h: 1, from: ChainDirection.topRight.rawValue, to: ChainDirection.down.rawValue),
        Run(t: 0, h: 1, from: ChainDirection.left.rawValue, to: ChainDirection.topRight.rawValue),
        Run.invalid,
        Run.invalid,

        // 101
        // 1 0
        // 110
        Run(t: 0, h: 1, from: ChainDirection.topRight.rawValue, to: ChainDirection.down.rawValue),
        Run(t: 0, h: 1, from: ChainDirection.topLeft.rawValue, to: ChainDirection.topRight.rawValue),
        Run.invalid,
        Run.invalid,

        // 011
        // 1 0
        // 110
        Run(t: 0, h: 1, from: ChainDirection.topRight.rawValue, to: ChainDirection.down.rawValue),
        Run.invalid,
        Run.invalid,
        Run.invalid,

        // 111
        // 1 0
        // 110
        Run(t: 0, h: 1, from: ChainDirection.topRight.rawValue, to: ChainDirection.down.rawValue),
        Run.invalid,
        Run.invalid,
        Run.invalid,

        // 000
        // 0 1
        // 110
        Run(t: 0, h: 1, from: ChainDirection.bottomLeft.rawValue, to: ChainDirection.right.rawValue),
        Run.invalid,
        Run.invalid,
        Run.invalid,

        // 100
        // 0 1
        // 110
        Run(t: 0, h: 1, from: ChainDirection.bottomLeft.rawValue, to: ChainDirection.topLeft.rawValue),
        Run(t: 0, h: 1, from: ChainDirection.topLeft.rawValue, to: ChainDirection.right.rawValue),
        Run.invalid,
        Run.invalid,

        // 010
        // 0 1
        // 110
        Run(t: 0, h: 1, from: ChainDirection.bottomLeft.rawValue, to: ChainDirection.up.rawValue),
        Run.invalid,
        Run.invalid,
        Run.invalid,

        // 110
        // 0 1
        // 110
        Run(t: 0, h: 1, from: ChainDirection.bottomLeft.rawValue, to: ChainDirection.topLeft.rawValue),
        Run.invalid,
        Run.invalid,
        Run.invalid,

        // 001
        // 0 1
        // 110
        Run(t: 0, h: 1, from: ChainDirection.bottomLeft.rawValue, to: ChainDirection.topRight.rawValue),
        Run.invalid,
        Run.invalid,
        Run.invalid,

        // 101
        // 0 1
        // 110
        Run(t: 0, h: 1, from: ChainDirection.bottomLeft.rawValue, to: ChainDirection.topLeft.rawValue),
        Run(t: 0, h: 1, from: ChainDirection.topLeft.rawValue, to: ChainDirection.topRight.rawValue),
        Run.invalid,
        Run.invalid,

        // 011
        // 0 1
        // 110
        Run(t: 0, h: 1, from: ChainDirection.bottomLeft.rawValue, to: ChainDirection.up.rawValue),
        Run.invalid,
        Run.invalid,
        Run.invalid,

        // 111
        // 0 1
        // 110
        Run(t: 0, h: 1, from: ChainDirection.bottomLeft.rawValue, to: ChainDirection.topLeft.rawValue),
        Run.invalid,
        Run.invalid,
        Run.invalid,

        // 000
        // 1 1
        // 110
        Run(t: 0, h: 1, from: ChainDirection.left.rawValue, to: ChainDirection.right.rawValue),
        Run.invalid,
        Run.invalid,
        Run.invalid,

        // 100
        // 1 1
        // 110
        Run(t: 0, h: 1, from: ChainDirection.topLeft.rawValue, to: ChainDirection.right.rawValue),
        Run.invalid,
        Run.invalid,
        Run.invalid,

        // 010
        // 1 1
        // 110
        Run.invalid,
        Run.invalid,
        Run.invalid,
        Run.invalid,

        // 110
        // 1 1
        // 110
        Run.invalid,
        Run.invalid,
        Run.invalid,
        Run.invalid,

        // 001
        // 1 1
        // 110
        Run(t: 0, h: 1, from: ChainDirection.left.rawValue, to: ChainDirection.topRight.rawValue),
        Run.invalid,
        Run.invalid,
        Run.invalid,

        // 101
        // 1 1
        // 110
        Run(t: 0, h: 1, from: ChainDirection.topLeft.rawValue, to: ChainDirection.topRight.rawValue),
        Run.invalid,
        Run.invalid,
        Run.invalid,

        // 011
        // 1 1
        // 110
        Run.invalid,
        Run.invalid,
        Run.invalid,
        Run.invalid,

        // 111
        // 1 1
        // 110
        Run.invalid,
        Run.invalid,
        Run.invalid,
        Run.invalid,

        // 000
        // 0 0
        // 001
        Run(t: 0, h: 1, from: ChainDirection.bottomRight.rawValue, to: ChainDirection.bottomRight.rawValue),
        Run.invalid,
        Run.invalid,
        Run.invalid,

        // 100
        // 0 0
        // 001
        Run(t: 0, h: 1, from: ChainDirection.bottomRight.rawValue, to: ChainDirection.topLeft.rawValue),
        Run(t: 0, h: 1, from: ChainDirection.topLeft.rawValue, to: ChainDirection.bottomRight.rawValue),
        Run.invalid,
        Run.invalid,

        // 010
        // 0 0
        // 001
        Run(t: 0, h: 1, from: ChainDirection.bottomRight.rawValue, to: ChainDirection.up.rawValue),
        Run(t: 0, h: 1, from: ChainDirection.up.rawValue, to: ChainDirection.bottomRight.rawValue),
        Run.invalid,
        Run.invalid,

        // 110
        // 0 0
        // 001
        Run(t: 0, h: 1, from: ChainDirection.bottomRight.rawValue, to: ChainDirection.topLeft.rawValue),
        Run(t: 0, h: 1, from: ChainDirection.up.rawValue, to: ChainDirection.bottomRight.rawValue),
        Run.invalid,
        Run.invalid,

        // 001
        // 0 0
        // 001
        Run(t: 0, h: 1, from: ChainDirection.topRight.rawValue, to: ChainDirection.bottomRight.rawValue),
        Run(t: 0, h: 1, from: ChainDirection.bottomRight.rawValue, to: ChainDirection.topRight.rawValue),
        Run.invalid,
        Run.invalid,

        // 101
        // 0 0
        // 001
        Run(t: 0, h: 1, from: ChainDirection.topRight.rawValue, to: ChainDirection.bottomRight.rawValue),
        Run(t: 0, h: 1, from: ChainDirection.bottomRight.rawValue, to: ChainDirection.topLeft.rawValue),
        Run(t: 0, h: 1, from: ChainDirection.topLeft.rawValue, to: ChainDirection.topRight.rawValue),
        Run.invalid,

        // 011
        // 0 0
        // 001
        Run(t: 0, h: 1, from: ChainDirection.topRight.rawValue, to: ChainDirection.bottomRight.rawValue),
        Run(t: 0, h: 1, from: ChainDirection.bottomRight.rawValue, to: ChainDirection.up.rawValue),
        Run.invalid,
        Run.invalid,

        // 111
        // 0 0
        // 001
        Run(t: 0, h: 1, from: ChainDirection.topRight.rawValue, to: ChainDirection.bottomRight.rawValue),
        Run(t: 0, h: 1, from: ChainDirection.bottomRight.rawValue, to: ChainDirection.topLeft.rawValue),
        Run.invalid,
        Run.invalid,

        // 000
        // 1 0
        // 001
        Run(t: 0, h: 1, from: ChainDirection.bottomRight.rawValue, to: ChainDirection.left.rawValue),
        Run(t: 0, h: 1, from: ChainDirection.left.rawValue, to: ChainDirection.bottomRight.rawValue),
        Run.invalid,
        Run.invalid,

        // 100
        // 1 0
        // 001
        Run(t: 0, h: 1, from: ChainDirection.bottomRight.rawValue, to: ChainDirection.left.rawValue),
        Run(t: 0, h: 1, from: ChainDirection.topLeft.rawValue, to: ChainDirection.bottomRight.rawValue),
        Run.invalid,
        Run.invalid,

        // 010
        // 1 0
        // 001
        Run(t: 0, h: 1, from: ChainDirection.bottomRight.rawValue, to: ChainDirection.left.rawValue),
        Run(t: 0, h: 1, from: ChainDirection.up.rawValue, to: ChainDirection.bottomRight.rawValue),
        Run.invalid,
        Run.invalid,

        // 110
        // 1 0
        // 001
        Run(t: 0, h: 1, from: ChainDirection.bottomRight.rawValue, to: ChainDirection.left.rawValue),
        Run(t: 0, h: 1, from: ChainDirection.up.rawValue, to: ChainDirection.bottomRight.rawValue),
        Run.invalid,
        Run.invalid,

        // 001
        // 1 0
        // 001
        Run(t: 0, h: 1, from: ChainDirection.topRight.rawValue, to: ChainDirection.bottomRight.rawValue),
        Run(t: 0, h: 1, from: ChainDirection.bottomRight.rawValue, to: ChainDirection.left.rawValue),
        Run(t: 0, h: 1, from: ChainDirection.left.rawValue, to: ChainDirection.topRight.rawValue),
        Run.invalid,

        // 101
        // 1 0
        // 001
        Run(t: 0, h: 1, from: ChainDirection.topRight.rawValue, to: ChainDirection.bottomRight.rawValue),
        Run(t: 0, h: 1, from: ChainDirection.bottomRight.rawValue, to: ChainDirection.left.rawValue),
        Run(t: 0, h: 1, from: ChainDirection.topLeft.rawValue, to: ChainDirection.topRight.rawValue),
        Run.invalid,

        // 011
        // 1 0
        // 001
        Run(t: 0, h: 1, from: ChainDirection.topRight.rawValue, to: ChainDirection.bottomRight.rawValue),
        Run(t: 0, h: 1, from: ChainDirection.bottomRight.rawValue, to: ChainDirection.left.rawValue),
        Run.invalid,
        Run.invalid,

        // 111
        // 1 0
        // 001
        Run(t: 0, h: 1, from: ChainDirection.topRight.rawValue, to: ChainDirection.bottomRight.rawValue),
        Run(t: 0, h: 1, from: ChainDirection.bottomRight.rawValue, to: ChainDirection.left.rawValue),
        Run.invalid,
        Run.invalid,

        // 000
        // 0 1
        // 001
        Run(t: 0, h: 1, from: ChainDirection.bottomRight.rawValue, to: ChainDirection.right.rawValue),
        Run.invalid,
        Run.invalid,
        Run.invalid,

        // 100
        // 0 1
        // 001
        Run(t: 0, h: 1, from: ChainDirection.bottomRight.rawValue, to: ChainDirection.topLeft.rawValue),
        Run(t: 0, h: 1, from: ChainDirection.topLeft.rawValue, to: ChainDirection.right.rawValue),
        Run.invalid,
        Run.invalid,

        // 010
        // 0 1
        // 001
        Run(t: 0, h: 1, from: ChainDirection.bottomRight.rawValue, to: ChainDirection.up.rawValue),
        Run.invalid,
        Run.invalid,
        Run.invalid,

        // 110
        // 0 1
        // 001
        Run(t: 0, h: 1, from: ChainDirection.bottomRight.rawValue, to: ChainDirection.topLeft.rawValue),
        Run.invalid,
        Run.invalid,
        Run.invalid,

        // 001
        // 0 1
        // 001
        Run(t: 0, h: 1, from: ChainDirection.bottomRight.rawValue, to: ChainDirection.topRight.rawValue),
        Run.invalid,
        Run.invalid,
        Run.invalid,

        // 101
        // 0 1
        // 001
        Run(t: 0, h: 1, from: ChainDirection.bottomRight.rawValue, to: ChainDirection.topLeft.rawValue),
        Run(t: 0, h: 1, from: ChainDirection.topLeft.rawValue, to: ChainDirection.topRight.rawValue),
        Run.invalid,
        Run.invalid,

        // 011
        // 0 1
        // 001
        Run(t: 0, h: 1, from: ChainDirection.bottomRight.rawValue, to: ChainDirection.up.rawValue),
        Run.invalid,
        Run.invalid,
        Run.invalid,

        // 111
        // 0 1
        // 001
        Run(t: 0, h: 1, from: ChainDirection.bottomRight.rawValue, to: ChainDirection.topLeft.rawValue),
        Run.invalid,
        Run.invalid,
        Run.invalid,

        // 000
        // 1 1
        // 001
        Run(t: 0, h: 1, from: ChainDirection.bottomRight.rawValue, to: ChainDirection.left.rawValue),
        Run(t: 0, h: 1, from: ChainDirection.left.rawValue, to: ChainDirection.right.rawValue),
        Run.invalid,
        Run.invalid,

        // 100
        // 1 1
        // 001
        Run(t: 0, h: 1, from: ChainDirection.bottomRight.rawValue, to: ChainDirection.left.rawValue),
        Run(t: 0, h: 1, from: ChainDirection.topLeft.rawValue, to: ChainDirection.right.rawValue),
        Run.invalid,
        Run.invalid,

        // 010
        // 1 1
        // 001
        Run(t: 0, h: 1, from: ChainDirection.bottomRight.rawValue, to: ChainDirection.left.rawValue),
        Run.invalid,
        Run.invalid,
        Run.invalid,

        // 110
        // 1 1
        // 001
        Run(t: 0, h: 1, from: ChainDirection.bottomRight.rawValue, to: ChainDirection.left.rawValue),
        Run.invalid,
        Run.invalid,
        Run.invalid,

        // 001
        // 1 1
        // 001
        Run(t: 0, h: 1, from: ChainDirection.bottomRight.rawValue, to: ChainDirection.left.rawValue),
        Run(t: 0, h: 1, from: ChainDirection.left.rawValue, to: ChainDirection.topRight.rawValue),
        Run.invalid,
        Run.invalid,

        // 101
        // 1 1
        // 001
        Run(t: 0, h: 1, from: ChainDirection.bottomRight.rawValue, to: ChainDirection.left.rawValue),
        Run(t: 0, h: 1, from: ChainDirection.topLeft.rawValue, to: ChainDirection.topRight.rawValue),
        Run.invalid,
        Run.invalid,

        // 011
        // 1 1
        // 001
        Run(t: 0, h: 1, from: ChainDirection.bottomRight.rawValue, to: ChainDirection.left.rawValue),
        Run.invalid,
        Run.invalid,
        Run.invalid,

        // 111
        // 1 1
        // 001
        Run(t: 0, h: 1, from: ChainDirection.bottomRight.rawValue, to: ChainDirection.left.rawValue),
        Run.invalid,
        Run.invalid,
        Run.invalid,

        // 000
        // 0 0
        // 101
        Run(t: 0, h: 1, from: ChainDirection.bottomRight.rawValue, to: ChainDirection.bottomLeft.rawValue),
        Run(t: 0, h: 1, from: ChainDirection.bottomLeft.rawValue, to: ChainDirection.bottomRight.rawValue),
        Run.invalid,
        Run.invalid,

        // 100
        // 0 0
        // 101
        Run(t: 0, h: 1, from: ChainDirection.bottomRight.rawValue, to: ChainDirection.bottomLeft.rawValue),
        Run(t: 0, h: 1, from: ChainDirection.bottomLeft.rawValue, to: ChainDirection.topLeft.rawValue),
        Run(t: 0, h: 1, from: ChainDirection.topLeft.rawValue, to: ChainDirection.bottomRight.rawValue),
        Run.invalid,

        // 010
        // 0 0
        // 101
        Run(t: 0, h: 1, from: ChainDirection.bottomRight.rawValue, to: ChainDirection.bottomLeft.rawValue),
        Run(t: 0, h: 1, from: ChainDirection.bottomLeft.rawValue, to: ChainDirection.up.rawValue),
        Run(t: 0, h: 1, from: ChainDirection.up.rawValue, to: ChainDirection.bottomRight.rawValue),
        Run.invalid,

        // 110
        // 0 0
        // 101
        Run(t: 0, h: 1, from: ChainDirection.bottomRight.rawValue, to: ChainDirection.bottomLeft.rawValue),
        Run(t: 0, h: 1, from: ChainDirection.bottomLeft.rawValue, to: ChainDirection.topLeft.rawValue),
        Run(t: 0, h: 1, from: ChainDirection.up.rawValue, to: ChainDirection.bottomRight.rawValue),
        Run.invalid,

        // 001
        // 0 0
        // 101
        Run(t: 0, h: 1, from: ChainDirection.topRight.rawValue, to: ChainDirection.bottomRight.rawValue),
        Run(t: 0, h: 1, from: ChainDirection.bottomRight.rawValue, to: ChainDirection.bottomLeft.rawValue),
        Run(t: 0, h: 1, from: ChainDirection.bottomLeft.rawValue, to: ChainDirection.topRight.rawValue),
        Run.invalid,

        // 101
        // 0 0
        // 101
        Run(t: 0, h: 1, from: ChainDirection.topRight.rawValue, to: ChainDirection.bottomRight.rawValue),
        Run(t: 0, h: 1, from: ChainDirection.bottomRight.rawValue, to: ChainDirection.bottomLeft.rawValue),
        Run(t: 0, h: 1, from: ChainDirection.bottomLeft.rawValue, to: ChainDirection.topLeft.rawValue),
        Run(t: 0, h: 1, from: ChainDirection.topLeft.rawValue, to: ChainDirection.topRight.rawValue),

        // 011
        // 0 0
        // 101
        Run(t: 0, h: 1, from: ChainDirection.topRight.rawValue, to: ChainDirection.bottomRight.rawValue),
        Run(t: 0, h: 1, from: ChainDirection.bottomRight.rawValue, to: ChainDirection.bottomLeft.rawValue),
        Run(t: 0, h: 1, from: ChainDirection.bottomLeft.rawValue, to: ChainDirection.up.rawValue),
        Run.invalid,

        // 111
        // 0 0
        // 101
        Run(t: 0, h: 1, from: ChainDirection.topRight.rawValue, to: ChainDirection.bottomRight.rawValue),
        Run(t: 0, h: 1, from: ChainDirection.bottomRight.rawValue, to: ChainDirection.bottomLeft.rawValue),
        Run(t: 0, h: 1, from: ChainDirection.bottomLeft.rawValue, to: ChainDirection.topLeft.rawValue),
        Run.invalid,

        // 000
        // 1 0
        // 101
        Run(t: 0, h: 1, from: ChainDirection.bottomRight.rawValue, to: ChainDirection.bottomLeft.rawValue),
        Run(t: 0, h: 1, from: ChainDirection.left.rawValue, to: ChainDirection.bottomRight.rawValue),
        Run.invalid,
        Run.invalid,

        // 100
        // 1 0
        // 101
        Run(t: 0, h: 1, from: ChainDirection.bottomRight.rawValue, to: ChainDirection.bottomLeft.rawValue),
        Run(t: 0, h: 1, from: ChainDirection.topLeft.rawValue, to: ChainDirection.bottomRight.rawValue),
        Run.invalid,
        Run.invalid,

        // 010
        // 1 0
        // 101
        Run(t: 0, h: 1, from: ChainDirection.bottomRight.rawValue, to: ChainDirection.bottomLeft.rawValue),
        Run(t: 0, h: 1, from: ChainDirection.up.rawValue, to: ChainDirection.bottomRight.rawValue),
        Run.invalid,
        Run.invalid,

        // 110
        // 1 0
        // 101
        Run(t: 0, h: 1, from: ChainDirection.bottomRight.rawValue, to: ChainDirection.bottomLeft.rawValue),
        Run(t: 0, h: 1, from: ChainDirection.up.rawValue, to: ChainDirection.bottomRight.rawValue),
        Run.invalid,
        Run.invalid,

        // 001
        // 1 0
        // 101
        Run(t: 0, h: 1, from: ChainDirection.topRight.rawValue, to: ChainDirection.bottomRight.rawValue),
        Run(t: 0, h: 1, from: ChainDirection.bottomRight.rawValue, to: ChainDirection.bottomLeft.rawValue),
        Run(t: 0, h: 1, from: ChainDirection.left.rawValue, to: ChainDirection.topRight.rawValue),
        Run.invalid,

        // 101
        // 1 0
        // 101
        Run(t: 0, h: 1, from: ChainDirection.topRight.rawValue, to: ChainDirection.bottomRight.rawValue),
        Run(t: 0, h: 1, from: ChainDirection.bottomRight.rawValue, to: ChainDirection.bottomLeft.rawValue),
        Run(t: 0, h: 1, from: ChainDirection.topLeft.rawValue, to: ChainDirection.topRight.rawValue),
        Run.invalid,

        // 011
        // 1 0
        // 101
        Run(t: 0, h: 1, from: ChainDirection.topRight.rawValue, to: ChainDirection.bottomRight.rawValue),
        Run(t: 0, h: 1, from: ChainDirection.bottomRight.rawValue, to: ChainDirection.bottomLeft.rawValue),
        Run.invalid,
        Run.invalid,

        // 111
        // 1 0
        // 101
        Run(t: 0, h: 1, from: ChainDirection.topRight.rawValue, to: ChainDirection.bottomRight.rawValue),
        Run(t: 0, h: 1, from: ChainDirection.bottomRight.rawValue, to: ChainDirection.bottomLeft.rawValue),
        Run.invalid,
        Run.invalid,

        // 000
        // 0 1
        // 101
        Run(t: 0, h: 1, from: ChainDirection.bottomRight.rawValue, to: ChainDirection.bottomLeft.rawValue),
        Run(t: 0, h: 1, from: ChainDirection.bottomLeft.rawValue, to: ChainDirection.right.rawValue),
        Run.invalid,
        Run.invalid,

        // 100
        // 0 1
        // 101
        Run(t: 0, h: 1, from: ChainDirection.bottomRight.rawValue, to: ChainDirection.bottomLeft.rawValue),
        Run(t: 0, h: 1, from: ChainDirection.bottomLeft.rawValue, to: ChainDirection.topLeft.rawValue),
        Run(t: 0, h: 1, from: ChainDirection.topLeft.rawValue, to: ChainDirection.right.rawValue),
        Run.invalid,

        // 010
        // 0 1
        // 101
        Run(t: 0, h: 1, from: ChainDirection.bottomRight.rawValue, to: ChainDirection.bottomLeft.rawValue),
        Run(t: 0, h: 1, from: ChainDirection.bottomLeft.rawValue, to: ChainDirection.up.rawValue),
        Run.invalid,
        Run.invalid,

        // 110
        // 0 1
        // 101
        Run(t: 0, h: 1, from: ChainDirection.bottomRight.rawValue, to: ChainDirection.bottomLeft.rawValue),
        Run(t: 0, h: 1, from: ChainDirection.bottomLeft.rawValue, to: ChainDirection.topLeft.rawValue),
        Run.invalid,
        Run.invalid,

        // 001
        // 0 1
        // 101
        Run(t: 0, h: 1, from: ChainDirection.bottomRight.rawValue, to: ChainDirection.bottomLeft.rawValue),
        Run(t: 0, h: 1, from: ChainDirection.bottomLeft.rawValue, to: ChainDirection.topRight.rawValue),
        Run.invalid,
        Run.invalid,

        // 101
        // 0 1
        // 101
        Run(t: 0, h: 1, from: ChainDirection.bottomRight.rawValue, to: ChainDirection.bottomLeft.rawValue),
        Run(t: 0, h: 1, from: ChainDirection.bottomLeft.rawValue, to: ChainDirection.topLeft.rawValue),
        Run(t: 0, h: 1, from: ChainDirection.topLeft.rawValue, to: ChainDirection.topRight.rawValue),
        Run.invalid,

        // 011
        // 0 1
        // 101
        Run(t: 0, h: 1, from: ChainDirection.bottomRight.rawValue, to: ChainDirection.bottomLeft.rawValue),
        Run(t: 0, h: 1, from: ChainDirection.bottomLeft.rawValue, to: ChainDirection.up.rawValue),
        Run.invalid,
        Run.invalid,

        // 111
        // 0 1
        // 101
        Run(t: 0, h: 1, from: ChainDirection.bottomRight.rawValue, to: ChainDirection.bottomLeft.rawValue),
        Run(t: 0, h: 1, from: ChainDirection.bottomLeft.rawValue, to: ChainDirection.topLeft.rawValue),
        Run.invalid,
        Run.invalid,

        // 000
        // 1 1
        // 101
        Run(t: 0, h: 1, from: ChainDirection.bottomRight.rawValue, to: ChainDirection.bottomLeft.rawValue),
        Run(t: 0, h: 1, from: ChainDirection.left.rawValue, to: ChainDirection.right.rawValue),
        Run.invalid,
        Run.invalid,

        // 100
        // 1 1
        // 101
        Run(t: 0, h: 1, from: ChainDirection.bottomRight.rawValue, to: ChainDirection.bottomLeft.rawValue),
        Run(t: 0, h: 1, from: ChainDirection.topLeft.rawValue, to: ChainDirection.right.rawValue),
        Run.invalid,
        Run.invalid,

        // 010
        // 1 1
        // 101
        Run(t: 0, h: 1, from: ChainDirection.bottomRight.rawValue, to: ChainDirection.bottomLeft.rawValue),
        Run.invalid,
        Run.invalid,
        Run.invalid,

        // 110
        // 1 1
        // 101
        Run(t: 0, h: 1, from: ChainDirection.bottomRight.rawValue, to: ChainDirection.bottomLeft.rawValue),
        Run.invalid,
        Run.invalid,
        Run.invalid,

        // 001
        // 1 1
        // 101
        Run(t: 0, h: 1, from: ChainDirection.bottomRight.rawValue, to: ChainDirection.bottomLeft.rawValue),
        Run(t: 0, h: 1, from: ChainDirection.left.rawValue, to: ChainDirection.topRight.rawValue),
        Run.invalid,
        Run.invalid,

        // 101
        // 1 1
        // 101
        Run(t: 0, h: 1, from: ChainDirection.bottomRight.rawValue, to: ChainDirection.bottomLeft.rawValue),
        Run(t: 0, h: 1, from: ChainDirection.topLeft.rawValue, to: ChainDirection.topRight.rawValue),
        Run.invalid,
        Run.invalid,

        // 011
        // 1 1
        // 101
        Run(t: 0, h: 1, from: ChainDirection.bottomRight.rawValue, to: ChainDirection.bottomLeft.rawValue),
        Run.invalid,
        Run.invalid,
        Run.invalid,

        // 111
        // 1 1
        // 101
        Run(t: 0, h: 1, from: ChainDirection.bottomRight.rawValue, to: ChainDirection.bottomLeft.rawValue),
        Run.invalid,
        Run.invalid,
        Run.invalid,

        // 000
        // 0 0
        // 011
        Run(t: 0, h: 1, from: ChainDirection.down.rawValue, to: ChainDirection.bottomRight.rawValue),
        Run.invalid,
        Run.invalid,
        Run.invalid,

        // 100
        // 0 0
        // 011
        Run(t: 0, h: 1, from: ChainDirection.down.rawValue, to: ChainDirection.topLeft.rawValue),
        Run(t: 0, h: 1, from: ChainDirection.topLeft.rawValue, to: ChainDirection.bottomRight.rawValue),
        Run.invalid,
        Run.invalid,

        // 010
        // 0 0
        // 011
        Run(t: 0, h: 1, from: ChainDirection.down.rawValue, to: ChainDirection.up.rawValue),
        Run(t: 0, h: 1, from: ChainDirection.up.rawValue, to: ChainDirection.bottomRight.rawValue),
        Run.invalid,
        Run.invalid,

        // 110
        // 0 0
        // 011
        Run(t: 0, h: 1, from: ChainDirection.down.rawValue, to: ChainDirection.topLeft.rawValue),
        Run(t: 0, h: 1, from: ChainDirection.up.rawValue, to: ChainDirection.bottomRight.rawValue),
        Run.invalid,
        Run.invalid,

        // 001
        // 0 0
        // 011
        Run(t: 0, h: 1, from: ChainDirection.topRight.rawValue, to: ChainDirection.bottomRight.rawValue),
        Run(t: 0, h: 1, from: ChainDirection.down.rawValue, to: ChainDirection.topRight.rawValue),
        Run.invalid,
        Run.invalid,

        // 101
        // 0 0
        // 011
        Run(t: 0, h: 1, from: ChainDirection.topRight.rawValue, to: ChainDirection.bottomRight.rawValue),
        Run(t: 0, h: 1, from: ChainDirection.down.rawValue, to: ChainDirection.topLeft.rawValue),
        Run(t: 0, h: 1, from: ChainDirection.topLeft.rawValue, to: ChainDirection.topRight.rawValue),
        Run.invalid,

        // 011
        // 0 0
        // 011
        Run(t: 0, h: 1, from: ChainDirection.topRight.rawValue, to: ChainDirection.bottomRight.rawValue),
        Run(t: 0, h: 1, from: ChainDirection.down.rawValue, to: ChainDirection.up.rawValue),
        Run.invalid,
        Run.invalid,

        // 111
        // 0 0
        // 011
        Run(t: 0, h: 1, from: ChainDirection.topRight.rawValue, to: ChainDirection.bottomRight.rawValue),
        Run(t: 0, h: 1, from: ChainDirection.down.rawValue, to: ChainDirection.topLeft.rawValue),
        Run.invalid,
        Run.invalid,

        // 000
        // 1 0
        // 011
        Run(t: 0, h: 1, from: ChainDirection.left.rawValue, to: ChainDirection.bottomRight.rawValue),
        Run.invalid,
        Run.invalid,
        Run.invalid,

        // 100
        // 1 0
        // 011
        Run(t: 0, h: 1, from: ChainDirection.topLeft.rawValue, to: ChainDirection.bottomRight.rawValue),
        Run.invalid,
        Run.invalid,
        Run.invalid,

        // 010
        // 1 0
        // 011
        Run(t: 0, h: 1, from: ChainDirection.up.rawValue, to: ChainDirection.bottomRight.rawValue),
        Run.invalid,
        Run.invalid,
        Run.invalid,

        // 110
        // 1 0
        // 011
        Run(t: 0, h: 1, from: ChainDirection.up.rawValue, to: ChainDirection.bottomRight.rawValue),
        Run.invalid,
        Run.invalid,
        Run.invalid,

        // 001
        // 1 0
        // 011
        Run(t: 0, h: 1, from: ChainDirection.topRight.rawValue, to: ChainDirection.bottomRight.rawValue),
        Run(t: 0, h: 1, from: ChainDirection.left.rawValue, to: ChainDirection.topRight.rawValue),
        Run.invalid,
        Run.invalid,

        // 101
        // 1 0
        // 011
        Run(t: 0, h: 1, from: ChainDirection.topRight.rawValue, to: ChainDirection.bottomRight.rawValue),
        Run(t: 0, h: 1, from: ChainDirection.topLeft.rawValue, to: ChainDirection.topRight.rawValue),
        Run.invalid,
        Run.invalid,

        // 011
        // 1 0
        // 011
        Run(t: 0, h: 1, from: ChainDirection.topRight.rawValue, to: ChainDirection.bottomRight.rawValue),
        Run.invalid,
        Run.invalid,
        Run.invalid,

        // 111
        // 1 0
        // 011
        Run(t: 0, h: 1, from: ChainDirection.topRight.rawValue, to: ChainDirection.bottomRight.rawValue),
        Run.invalid,
        Run.invalid,
        Run.invalid,

        // 000
        // 0 1
        // 011
        Run(t: 0, h: 1, from: ChainDirection.down.rawValue, to: ChainDirection.right.rawValue),
        Run.invalid,
        Run.invalid,
        Run.invalid,

        // 100
        // 0 1
        // 011
        Run(t: 0, h: 1, from: ChainDirection.down.rawValue, to: ChainDirection.topLeft.rawValue),
        Run(t: 0, h: 1, from: ChainDirection.topLeft.rawValue, to: ChainDirection.right.rawValue),
        Run.invalid,
        Run.invalid,

        // 010
        // 0 1
        // 011
        Run(t: 0, h: 1, from: ChainDirection.down.rawValue, to: ChainDirection.up.rawValue),
        Run.invalid,
        Run.invalid,
        Run.invalid,

        // 110
        // 0 1
        // 011
        Run(t: 0, h: 1, from: ChainDirection.down.rawValue, to: ChainDirection.topLeft.rawValue),
        Run.invalid,
        Run.invalid,
        Run.invalid,

        // 001
        // 0 1
        // 011
        Run(t: 0, h: 1, from: ChainDirection.down.rawValue, to: ChainDirection.topRight.rawValue),
        Run.invalid,
        Run.invalid,
        Run.invalid,

        // 101
        // 0 1
        // 011
        Run(t: 0, h: 1, from: ChainDirection.down.rawValue, to: ChainDirection.topLeft.rawValue),
        Run(t: 0, h: 1, from: ChainDirection.topLeft.rawValue, to: ChainDirection.topRight.rawValue),
        Run.invalid,
        Run.invalid,

        // 011
        // 0 1
        // 011
        Run(t: 0, h: 1, from: ChainDirection.down.rawValue, to: ChainDirection.up.rawValue),
        Run.invalid,
        Run.invalid,
        Run.invalid,

        // 111
        // 0 1
        // 011
        Run(t: 0, h: 1, from: ChainDirection.down.rawValue, to: ChainDirection.topLeft.rawValue),
        Run.invalid,
        Run.invalid,
        Run.invalid,

        // 000
        // 1 1
        // 011
        Run(t: 0, h: 1, from: ChainDirection.left.rawValue, to: ChainDirection.right.rawValue),
        Run.invalid,
        Run.invalid,
        Run.invalid,

        // 100
        // 1 1
        // 011
        Run(t: 0, h: 1, from: ChainDirection.topLeft.rawValue, to: ChainDirection.right.rawValue),
        Run.invalid,
        Run.invalid,
        Run.invalid,

        // 010
        // 1 1
        // 011
        Run.invalid,
        Run.invalid,
        Run.invalid,
        Run.invalid,

        // 110
        // 1 1
        // 011
        Run.invalid,
        Run.invalid,
        Run.invalid,
        Run.invalid,

        // 001
        // 1 1
        // 011
        Run(t: 0, h: 1, from: ChainDirection.left.rawValue, to: ChainDirection.topRight.rawValue),
        Run.invalid,
        Run.invalid,
        Run.invalid,

        // 101
        // 1 1
        // 011
        Run(t: 0, h: 1, from: ChainDirection.topLeft.rawValue, to: ChainDirection.topRight.rawValue),
        Run.invalid,
        Run.invalid,
        Run.invalid,

        // 011
        // 1 1
        // 011
        Run.invalid,
        Run.invalid,
        Run.invalid,
        Run.invalid,

        // 111
        // 1 1
        // 011
        Run.invalid,
        Run.invalid,
        Run.invalid,
        Run.invalid,

        // 000
        // 0 0
        // 111
        Run(t: 0, h: 1, from: ChainDirection.bottomLeft.rawValue, to: ChainDirection.bottomRight.rawValue),
        Run.invalid,
        Run.invalid,
        Run.invalid,

        // 100
        // 0 0
        // 111
        Run(t: 0, h: 1, from: ChainDirection.bottomLeft.rawValue, to: ChainDirection.topLeft.rawValue),
        Run(t: 0, h: 1, from: ChainDirection.topLeft.rawValue, to: ChainDirection.bottomRight.rawValue),
        Run.invalid,
        Run.invalid,

        // 010
        // 0 0
        // 111
        Run(t: 0, h: 1, from: ChainDirection.bottomLeft.rawValue, to: ChainDirection.up.rawValue),
        Run(t: 0, h: 1, from: ChainDirection.up.rawValue, to: ChainDirection.bottomRight.rawValue),
        Run.invalid,
        Run.invalid,

        // 110
        // 0 0
        // 111
        Run(t: 0, h: 1, from: ChainDirection.bottomLeft.rawValue, to: ChainDirection.topLeft.rawValue),
        Run(t: 0, h: 1, from: ChainDirection.up.rawValue, to: ChainDirection.bottomRight.rawValue),
        Run.invalid,
        Run.invalid,

        // 001
        // 0 0
        // 111
        Run(t: 0, h: 1, from: ChainDirection.topRight.rawValue, to: ChainDirection.bottomRight.rawValue),
        Run(t: 0, h: 1, from: ChainDirection.bottomLeft.rawValue, to: ChainDirection.topRight.rawValue),
        Run.invalid,
        Run.invalid,

        // 101
        // 0 0
        // 111
        Run(t: 0, h: 1, from: ChainDirection.topRight.rawValue, to: ChainDirection.bottomRight.rawValue),
        Run(t: 0, h: 1, from: ChainDirection.bottomLeft.rawValue, to: ChainDirection.topLeft.rawValue),
        Run(t: 0, h: 1, from: ChainDirection.topLeft.rawValue, to: ChainDirection.topRight.rawValue),
        Run.invalid,

        // 011
        // 0 0
        // 111
        Run(t: 0, h: 1, from: ChainDirection.topRight.rawValue, to: ChainDirection.bottomRight.rawValue),
        Run(t: 0, h: 1, from: ChainDirection.bottomLeft.rawValue, to: ChainDirection.up.rawValue),
        Run.invalid,
        Run.invalid,

        // 111
        // 0 0
        // 111
        Run(t: 0, h: 1, from: ChainDirection.topRight.rawValue, to: ChainDirection.bottomRight.rawValue),
        Run(t: 0, h: 1, from: ChainDirection.bottomLeft.rawValue, to: ChainDirection.topLeft.rawValue),
        Run.invalid,
        Run.invalid,

        // 000
        // 1 0
        // 111
        Run(t: 0, h: 1, from: ChainDirection.left.rawValue, to: ChainDirection.bottomRight.rawValue),
        Run.invalid,
        Run.invalid,
        Run.invalid,

        // 100
        // 1 0
        // 111
        Run(t: 0, h: 1, from: ChainDirection.topLeft.rawValue, to: ChainDirection.bottomRight.rawValue),
        Run.invalid,
        Run.invalid,
        Run.invalid,

        // 010
        // 1 0
        // 111
        Run(t: 0, h: 1, from: ChainDirection.up.rawValue, to: ChainDirection.bottomRight.rawValue),
        Run.invalid,
        Run.invalid,
        Run.invalid,

        // 110
        // 1 0
        // 111
        Run(t: 0, h: 1, from: ChainDirection.up.rawValue, to: ChainDirection.bottomRight.rawValue),
        Run.invalid,
        Run.invalid,
        Run.invalid,

        // 001
        // 1 0
        // 111
        Run(t: 0, h: 1, from: ChainDirection.topRight.rawValue, to: ChainDirection.bottomRight.rawValue),
        Run(t: 0, h: 1, from: ChainDirection.left.rawValue, to: ChainDirection.topRight.rawValue),
        Run.invalid,
        Run.invalid,

        // 101
        // 1 0
        // 111
        Run(t: 0, h: 1, from: ChainDirection.topRight.rawValue, to: ChainDirection.bottomRight.rawValue),
        Run(t: 0, h: 1, from: ChainDirection.topLeft.rawValue, to: ChainDirection.topRight.rawValue),
        Run.invalid,
        Run.invalid,

        // 011
        // 1 0
        // 111
        Run(t: 0, h: 1, from: ChainDirection.topRight.rawValue, to: ChainDirection.bottomRight.rawValue),
        Run.invalid,
        Run.invalid,
        Run.invalid,

        // 111
        // 1 0
        // 111
        Run(t: 0, h: 1, from: ChainDirection.topRight.rawValue, to: ChainDirection.bottomRight.rawValue),
        Run.invalid,
        Run.invalid,
        Run.invalid,

        // 000
        // 0 1
        // 111
        Run(t: 0, h: 1, from: ChainDirection.bottomLeft.rawValue, to: ChainDirection.right.rawValue),
        Run.invalid,
        Run.invalid,
        Run.invalid,

        // 100
        // 0 1
        // 111
        Run(t: 0, h: 1, from: ChainDirection.bottomLeft.rawValue, to: ChainDirection.topLeft.rawValue),
        Run(t: 0, h: 1, from: ChainDirection.topLeft.rawValue, to: ChainDirection.right.rawValue),
        Run.invalid,
        Run.invalid,

        // 010
        // 0 1
        // 111
        Run(t: 0, h: 1, from: ChainDirection.bottomLeft.rawValue, to: ChainDirection.up.rawValue),
        Run.invalid,
        Run.invalid,
        Run.invalid,

        // 110
        // 0 1
        // 111
        Run(t: 0, h: 1, from: ChainDirection.bottomLeft.rawValue, to: ChainDirection.topLeft.rawValue),
        Run.invalid,
        Run.invalid,
        Run.invalid,

        // 001
        // 0 1
        // 111
        Run(t: 0, h: 1, from: ChainDirection.bottomLeft.rawValue, to: ChainDirection.topRight.rawValue),
        Run.invalid,
        Run.invalid,
        Run.invalid,

        // 101
        // 0 1
        // 111
        Run(t: 0, h: 1, from: ChainDirection.bottomLeft.rawValue, to: ChainDirection.topLeft.rawValue),
        Run(t: 0, h: 1, from: ChainDirection.topLeft.rawValue, to: ChainDirection.topRight.rawValue),
        Run.invalid,
        Run.invalid,

        // 011
        // 0 1
        // 111
        Run(t: 0, h: 1, from: ChainDirection.bottomLeft.rawValue, to: ChainDirection.up.rawValue),
        Run.invalid,
        Run.invalid,
        Run.invalid,

        // 111
        // 0 1
        // 111
        Run(t: 0, h: 1, from: ChainDirection.bottomLeft.rawValue, to: ChainDirection.topLeft.rawValue),
        Run.invalid,
        Run.invalid,
        Run.invalid,

        // 000
        // 1 1
        // 111
        Run(t: 0, h: 1, from: ChainDirection.left.rawValue, to: ChainDirection.right.rawValue),
        Run.invalid,
        Run.invalid,
        Run.invalid,

        // 100
        // 1 1
        // 111
        Run(t: 0, h: 1, from: ChainDirection.topLeft.rawValue, to: ChainDirection.right.rawValue),
        Run.invalid,
        Run.invalid,
        Run.invalid,

        // 010
        // 1 1
        // 111
        Run.invalid,
        Run.invalid,
        Run.invalid,
        Run.invalid,

        // 110
        // 1 1
        // 111
        Run.invalid,
        Run.invalid,
        Run.invalid,
        Run.invalid,

        // 001
        // 1 1
        // 111
        Run(t: 0, h: 1, from: ChainDirection.left.rawValue, to: ChainDirection.topRight.rawValue),
        Run.invalid,
        Run.invalid,
        Run.invalid,

        // 101
        // 1 1
        // 111
        Run(t: 0, h: 1, from: ChainDirection.topLeft.rawValue, to: ChainDirection.topRight.rawValue),
        Run.invalid,
        Run.invalid,
        Run.invalid,

        // 011
        // 1 1
        // 111
        Run.invalid,
        Run.invalid,
        Run.invalid,
        Run.invalid,

        // 111
        // 1 1
        // 111
        Run.invalid,
        Run.invalid,
        Run.invalid,
        Run.invalid,
    ]
}
