//
//  PointLUT.swift
//  
//
//  Created by Secret Asian Man Dev on 15/2/23.
//

import Foundation
import Metal

extension StartPoint {
    /// Set by `LookupTableBuilder`.
    static var lookupTableIndices: Buffer<UInt16>! = nil
    
    /// Set by `LookupTableBuilder`.
    static var lookupTable: Buffer<Self>! = nil
}

extension PixelPoint {
    
    static var LUTBuffer: Buffer<PixelPoint>? = {
        let device = MTLCreateSystemDefaultDevice()!
        guard let buffer = Buffer<PixelPoint>.init(device: device, count: LUT.count) else {
            assertionFailure("Failed to create LUT buffer")
            return nil
        }
        memcpy(buffer.array, LUT, MemoryLayout<PixelPoint>.stride * LUT.count)
        return buffer
    }()
    
    static let LUT: [PixelPoint] = [
        // 000
        // 0 0
        // 000
        PixelPoint.invalid,
        PixelPoint.invalid,
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 100
        // 0 0
        // 000
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 010
        // 0 0
        // 000
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 110
        // 0 0
        // 000
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 001
        // 0 0
        // 000
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 101
        // 0 0
        // 000
        PixelPoint(x: 0, y: 0),
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 011
        // 0 0
        // 000
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 111
        // 0 0
        // 000
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 000
        // 1 0
        // 000
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 100
        // 1 0
        // 000
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 010
        // 1 0
        // 000
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 110
        // 1 0
        // 000
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 001
        // 1 0
        // 000
        PixelPoint(x: 0, y: 0),
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 101
        // 1 0
        // 000
        PixelPoint(x: 0, y: 0),
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 011
        // 1 0
        // 000
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 111
        // 1 0
        // 000
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 000
        // 0 1
        // 000
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 100
        // 0 1
        // 000
        PixelPoint(x: 0, y: 0),
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 010
        // 0 1
        // 000
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 110
        // 0 1
        // 000
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 001
        // 0 1
        // 000
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 101
        // 0 1
        // 000
        PixelPoint(x: 0, y: 0),
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 011
        // 0 1
        // 000
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 111
        // 0 1
        // 000
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 000
        // 1 1
        // 000
        PixelPoint(x: 0, y: 0),
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 100
        // 1 1
        // 000
        PixelPoint(x: 0, y: 0),
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 010
        // 1 1
        // 000
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 110
        // 1 1
        // 000
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 001
        // 1 1
        // 000
        PixelPoint(x: 0, y: 0),
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 101
        // 1 1
        // 000
        PixelPoint(x: 0, y: 0),
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 011
        // 1 1
        // 000
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 111
        // 1 1
        // 000
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 000
        // 0 0
        // 100
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 100
        // 0 0
        // 100
        PixelPoint(x: 0, y: 0),
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 010
        // 0 0
        // 100
        PixelPoint(x: 0, y: 0),
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 110
        // 0 0
        // 100
        PixelPoint(x: 0, y: 0),
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 001
        // 0 0
        // 100
        PixelPoint(x: 0, y: 0),
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 101
        // 0 0
        // 100
        PixelPoint(x: 0, y: 0),
        PixelPoint(x: 0, y: 0),
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,

        // 011
        // 0 0
        // 100
        PixelPoint(x: 0, y: 0),
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 111
        // 0 0
        // 100
        PixelPoint(x: 0, y: 0),
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 000
        // 1 0
        // 100
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 100
        // 1 0
        // 100
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 010
        // 1 0
        // 100
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 110
        // 1 0
        // 100
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 001
        // 1 0
        // 100
        PixelPoint(x: 0, y: 0),
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 101
        // 1 0
        // 100
        PixelPoint(x: 0, y: 0),
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 011
        // 1 0
        // 100
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 111
        // 1 0
        // 100
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 000
        // 0 1
        // 100
        PixelPoint(x: 0, y: 0),
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 100
        // 0 1
        // 100
        PixelPoint(x: 0, y: 0),
        PixelPoint(x: 0, y: 0),
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,

        // 010
        // 0 1
        // 100
        PixelPoint(x: 0, y: 0),
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 110
        // 0 1
        // 100
        PixelPoint(x: 0, y: 0),
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 001
        // 0 1
        // 100
        PixelPoint(x: 0, y: 0),
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 101
        // 0 1
        // 100
        PixelPoint(x: 0, y: 0),
        PixelPoint(x: 0, y: 0),
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,

        // 011
        // 0 1
        // 100
        PixelPoint(x: 0, y: 0),
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 111
        // 0 1
        // 100
        PixelPoint(x: 0, y: 0),
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 000
        // 1 1
        // 100
        PixelPoint(x: 0, y: 0),
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 100
        // 1 1
        // 100
        PixelPoint(x: 0, y: 0),
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 010
        // 1 1
        // 100
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 110
        // 1 1
        // 100
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 001
        // 1 1
        // 100
        PixelPoint(x: 0, y: 0),
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 101
        // 1 1
        // 100
        PixelPoint(x: 0, y: 0),
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 011
        // 1 1
        // 100
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 111
        // 1 1
        // 100
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 000
        // 0 0
        // 010
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 100
        // 0 0
        // 010
        PixelPoint(x: 0, y: 0),
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 010
        // 0 0
        // 010
        PixelPoint(x: 0, y: 0),
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 110
        // 0 0
        // 010
        PixelPoint(x: 0, y: 0),
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 001
        // 0 0
        // 010
        PixelPoint(x: 0, y: 0),
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 101
        // 0 0
        // 010
        PixelPoint(x: 0, y: 0),
        PixelPoint(x: 0, y: 0),
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,

        // 011
        // 0 0
        // 010
        PixelPoint(x: 0, y: 0),
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 111
        // 0 0
        // 010
        PixelPoint(x: 0, y: 0),
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 000
        // 1 0
        // 010
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 100
        // 1 0
        // 010
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 010
        // 1 0
        // 010
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 110
        // 1 0
        // 010
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 001
        // 1 0
        // 010
        PixelPoint(x: 0, y: 0),
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 101
        // 1 0
        // 010
        PixelPoint(x: 0, y: 0),
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 011
        // 1 0
        // 010
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 111
        // 1 0
        // 010
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 000
        // 0 1
        // 010
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 100
        // 0 1
        // 010
        PixelPoint(x: 0, y: 0),
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 010
        // 0 1
        // 010
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 110
        // 0 1
        // 010
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 001
        // 0 1
        // 010
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 101
        // 0 1
        // 010
        PixelPoint(x: 0, y: 0),
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 011
        // 0 1
        // 010
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 111
        // 0 1
        // 010
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 000
        // 1 1
        // 010
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 100
        // 1 1
        // 010
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 010
        // 1 1
        // 010
        PixelPoint.invalid,
        PixelPoint.invalid,
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 110
        // 1 1
        // 010
        PixelPoint.invalid,
        PixelPoint.invalid,
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 001
        // 1 1
        // 010
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 101
        // 1 1
        // 010
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 011
        // 1 1
        // 010
        PixelPoint.invalid,
        PixelPoint.invalid,
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 111
        // 1 1
        // 010
        PixelPoint.invalid,
        PixelPoint.invalid,
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 000
        // 0 0
        // 110
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 100
        // 0 0
        // 110
        PixelPoint(x: 0, y: 0),
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 010
        // 0 0
        // 110
        PixelPoint(x: 0, y: 0),
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 110
        // 0 0
        // 110
        PixelPoint(x: 0, y: 0),
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 001
        // 0 0
        // 110
        PixelPoint(x: 0, y: 0),
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 101
        // 0 0
        // 110
        PixelPoint(x: 0, y: 0),
        PixelPoint(x: 0, y: 0),
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,

        // 011
        // 0 0
        // 110
        PixelPoint(x: 0, y: 0),
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 111
        // 0 0
        // 110
        PixelPoint(x: 0, y: 0),
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 000
        // 1 0
        // 110
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 100
        // 1 0
        // 110
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 010
        // 1 0
        // 110
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 110
        // 1 0
        // 110
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 001
        // 1 0
        // 110
        PixelPoint(x: 0, y: 0),
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 101
        // 1 0
        // 110
        PixelPoint(x: 0, y: 0),
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 011
        // 1 0
        // 110
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 111
        // 1 0
        // 110
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 000
        // 0 1
        // 110
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 100
        // 0 1
        // 110
        PixelPoint(x: 0, y: 0),
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 010
        // 0 1
        // 110
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 110
        // 0 1
        // 110
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 001
        // 0 1
        // 110
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 101
        // 0 1
        // 110
        PixelPoint(x: 0, y: 0),
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 011
        // 0 1
        // 110
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 111
        // 0 1
        // 110
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 000
        // 1 1
        // 110
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 100
        // 1 1
        // 110
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 010
        // 1 1
        // 110
        PixelPoint.invalid,
        PixelPoint.invalid,
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 110
        // 1 1
        // 110
        PixelPoint.invalid,
        PixelPoint.invalid,
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 001
        // 1 1
        // 110
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 101
        // 1 1
        // 110
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 011
        // 1 1
        // 110
        PixelPoint.invalid,
        PixelPoint.invalid,
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 111
        // 1 1
        // 110
        PixelPoint.invalid,
        PixelPoint.invalid,
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 000
        // 0 0
        // 001
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 100
        // 0 0
        // 001
        PixelPoint(x: 0, y: 0),
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 010
        // 0 0
        // 001
        PixelPoint(x: 0, y: 0),
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 110
        // 0 0
        // 001
        PixelPoint(x: 0, y: 0),
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 001
        // 0 0
        // 001
        PixelPoint(x: 0, y: 0),
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 101
        // 0 0
        // 001
        PixelPoint(x: 0, y: 0),
        PixelPoint(x: 0, y: 0),
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,

        // 011
        // 0 0
        // 001
        PixelPoint(x: 0, y: 0),
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 111
        // 0 0
        // 001
        PixelPoint(x: 0, y: 0),
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 000
        // 1 0
        // 001
        PixelPoint(x: 0, y: 0),
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 100
        // 1 0
        // 001
        PixelPoint(x: 0, y: 0),
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 010
        // 1 0
        // 001
        PixelPoint(x: 0, y: 0),
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 110
        // 1 0
        // 001
        PixelPoint(x: 0, y: 0),
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 001
        // 1 0
        // 001
        PixelPoint(x: 0, y: 0),
        PixelPoint(x: 0, y: 0),
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,

        // 101
        // 1 0
        // 001
        PixelPoint(x: 0, y: 0),
        PixelPoint(x: 0, y: 0),
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,

        // 011
        // 1 0
        // 001
        PixelPoint(x: 0, y: 0),
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 111
        // 1 0
        // 001
        PixelPoint(x: 0, y: 0),
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 000
        // 0 1
        // 001
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 100
        // 0 1
        // 001
        PixelPoint(x: 0, y: 0),
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 010
        // 0 1
        // 001
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 110
        // 0 1
        // 001
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 001
        // 0 1
        // 001
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 101
        // 0 1
        // 001
        PixelPoint(x: 0, y: 0),
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 011
        // 0 1
        // 001
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 111
        // 0 1
        // 001
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 000
        // 1 1
        // 001
        PixelPoint(x: 0, y: 0),
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 100
        // 1 1
        // 001
        PixelPoint(x: 0, y: 0),
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 010
        // 1 1
        // 001
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 110
        // 1 1
        // 001
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 001
        // 1 1
        // 001
        PixelPoint(x: 0, y: 0),
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 101
        // 1 1
        // 001
        PixelPoint(x: 0, y: 0),
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 011
        // 1 1
        // 001
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 111
        // 1 1
        // 001
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 000
        // 0 0
        // 101
        PixelPoint(x: 0, y: 0),
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 100
        // 0 0
        // 101
        PixelPoint(x: 0, y: 0),
        PixelPoint(x: 0, y: 0),
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,

        // 010
        // 0 0
        // 101
        PixelPoint(x: 0, y: 0),
        PixelPoint(x: 0, y: 0),
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,

        // 110
        // 0 0
        // 101
        PixelPoint(x: 0, y: 0),
        PixelPoint(x: 0, y: 0),
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,

        // 001
        // 0 0
        // 101
        PixelPoint(x: 0, y: 0),
        PixelPoint(x: 0, y: 0),
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,

        // 101
        // 0 0
        // 101
        PixelPoint(x: 0, y: 0),
        PixelPoint(x: 0, y: 0),
        PixelPoint(x: 0, y: 0),
        PixelPoint(x: 0, y: 0),

        // 011
        // 0 0
        // 101
        PixelPoint(x: 0, y: 0),
        PixelPoint(x: 0, y: 0),
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,

        // 111
        // 0 0
        // 101
        PixelPoint(x: 0, y: 0),
        PixelPoint(x: 0, y: 0),
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,

        // 000
        // 1 0
        // 101
        PixelPoint(x: 0, y: 0),
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 100
        // 1 0
        // 101
        PixelPoint(x: 0, y: 0),
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 010
        // 1 0
        // 101
        PixelPoint(x: 0, y: 0),
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 110
        // 1 0
        // 101
        PixelPoint(x: 0, y: 0),
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 001
        // 1 0
        // 101
        PixelPoint(x: 0, y: 0),
        PixelPoint(x: 0, y: 0),
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,

        // 101
        // 1 0
        // 101
        PixelPoint(x: 0, y: 0),
        PixelPoint(x: 0, y: 0),
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,

        // 011
        // 1 0
        // 101
        PixelPoint(x: 0, y: 0),
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 111
        // 1 0
        // 101
        PixelPoint(x: 0, y: 0),
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 000
        // 0 1
        // 101
        PixelPoint(x: 0, y: 0),
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 100
        // 0 1
        // 101
        PixelPoint(x: 0, y: 0),
        PixelPoint(x: 0, y: 0),
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,

        // 010
        // 0 1
        // 101
        PixelPoint(x: 0, y: 0),
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 110
        // 0 1
        // 101
        PixelPoint(x: 0, y: 0),
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 001
        // 0 1
        // 101
        PixelPoint(x: 0, y: 0),
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 101
        // 0 1
        // 101
        PixelPoint(x: 0, y: 0),
        PixelPoint(x: 0, y: 0),
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,

        // 011
        // 0 1
        // 101
        PixelPoint(x: 0, y: 0),
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 111
        // 0 1
        // 101
        PixelPoint(x: 0, y: 0),
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 000
        // 1 1
        // 101
        PixelPoint(x: 0, y: 0),
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 100
        // 1 1
        // 101
        PixelPoint(x: 0, y: 0),
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 010
        // 1 1
        // 101
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 110
        // 1 1
        // 101
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 001
        // 1 1
        // 101
        PixelPoint(x: 0, y: 0),
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 101
        // 1 1
        // 101
        PixelPoint(x: 0, y: 0),
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 011
        // 1 1
        // 101
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 111
        // 1 1
        // 101
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 000
        // 0 0
        // 011
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 100
        // 0 0
        // 011
        PixelPoint(x: 0, y: 0),
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 010
        // 0 0
        // 011
        PixelPoint(x: 0, y: 0),
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 110
        // 0 0
        // 011
        PixelPoint(x: 0, y: 0),
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 001
        // 0 0
        // 011
        PixelPoint(x: 0, y: 0),
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 101
        // 0 0
        // 011
        PixelPoint(x: 0, y: 0),
        PixelPoint(x: 0, y: 0),
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,

        // 011
        // 0 0
        // 011
        PixelPoint(x: 0, y: 0),
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 111
        // 0 0
        // 011
        PixelPoint(x: 0, y: 0),
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 000
        // 1 0
        // 011
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 100
        // 1 0
        // 011
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 010
        // 1 0
        // 011
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 110
        // 1 0
        // 011
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 001
        // 1 0
        // 011
        PixelPoint(x: 0, y: 0),
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 101
        // 1 0
        // 011
        PixelPoint(x: 0, y: 0),
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 011
        // 1 0
        // 011
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 111
        // 1 0
        // 011
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 000
        // 0 1
        // 011
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 100
        // 0 1
        // 011
        PixelPoint(x: 0, y: 0),
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 010
        // 0 1
        // 011
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 110
        // 0 1
        // 011
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 001
        // 0 1
        // 011
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 101
        // 0 1
        // 011
        PixelPoint(x: 0, y: 0),
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 011
        // 0 1
        // 011
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 111
        // 0 1
        // 011
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 000
        // 1 1
        // 011
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 100
        // 1 1
        // 011
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 010
        // 1 1
        // 011
        PixelPoint.invalid,
        PixelPoint.invalid,
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 110
        // 1 1
        // 011
        PixelPoint.invalid,
        PixelPoint.invalid,
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 001
        // 1 1
        // 011
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 101
        // 1 1
        // 011
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 011
        // 1 1
        // 011
        PixelPoint.invalid,
        PixelPoint.invalid,
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 111
        // 1 1
        // 011
        PixelPoint.invalid,
        PixelPoint.invalid,
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 000
        // 0 0
        // 111
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 100
        // 0 0
        // 111
        PixelPoint(x: 0, y: 0),
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 010
        // 0 0
        // 111
        PixelPoint(x: 0, y: 0),
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 110
        // 0 0
        // 111
        PixelPoint(x: 0, y: 0),
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 001
        // 0 0
        // 111
        PixelPoint(x: 0, y: 0),
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 101
        // 0 0
        // 111
        PixelPoint(x: 0, y: 0),
        PixelPoint(x: 0, y: 0),
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,

        // 011
        // 0 0
        // 111
        PixelPoint(x: 0, y: 0),
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 111
        // 0 0
        // 111
        PixelPoint(x: 0, y: 0),
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 000
        // 1 0
        // 111
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 100
        // 1 0
        // 111
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 010
        // 1 0
        // 111
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 110
        // 1 0
        // 111
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 001
        // 1 0
        // 111
        PixelPoint(x: 0, y: 0),
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 101
        // 1 0
        // 111
        PixelPoint(x: 0, y: 0),
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 011
        // 1 0
        // 111
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 111
        // 1 0
        // 111
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 000
        // 0 1
        // 111
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 100
        // 0 1
        // 111
        PixelPoint(x: 0, y: 0),
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 010
        // 0 1
        // 111
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 110
        // 0 1
        // 111
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 001
        // 0 1
        // 111
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 101
        // 0 1
        // 111
        PixelPoint(x: 0, y: 0),
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 011
        // 0 1
        // 111
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 111
        // 0 1
        // 111
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 000
        // 1 1
        // 111
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 100
        // 1 1
        // 111
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 010
        // 1 1
        // 111
        PixelPoint.invalid,
        PixelPoint.invalid,
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 110
        // 1 1
        // 111
        PixelPoint.invalid,
        PixelPoint.invalid,
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 001
        // 1 1
        // 111
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 101
        // 1 1
        // 111
        PixelPoint(x: 0, y: 0),
        PixelPoint.invalid,
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 011
        // 1 1
        // 111
        PixelPoint.invalid,
        PixelPoint.invalid,
        PixelPoint.invalid,
        PixelPoint.invalid,

        // 111
        // 1 1
        // 111
        PixelPoint.invalid,
        PixelPoint.invalid,
        PixelPoint.invalid,
        PixelPoint.invalid,
    ]
}
