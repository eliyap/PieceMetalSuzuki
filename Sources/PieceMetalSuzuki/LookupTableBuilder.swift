//
//  LookupTableBuilder.swift
//  
//
//  Created by Secret Asian Man Dev on 15/2/23.
//

import Foundation
import CoreVideo

/**
 The objective of a Lookup Table is to quick-start the creation of a `Region` from a pattern.
 
 A "pattern" is an arrangement of initial on / off pixels.
 It consists of
 - a core: the pixels we're interested in, which the `Region` covers
 - a perimeter: the immediate surroundings, which inform how this `Region` will combine with adjoining ones.
 
 For example, here's a simple 3x3 pattern, with a 1x1 core:
 ```
 101
 010
 101
 ```
 This pattern produces 4 distinct runs; the most any 3x3 pattern can have.
 Hence, the 3x3 lookup table has 4 columns.
 */
internal final class LookupTableBuilder {
    
    /// Contains distinct series of points.
    var pointTable: [[StartPoint]] = []
    var pointIndices: [Int] = []
    
    /// Contains distinct series of runs.
    var runTable: [[StartRun]] = []
    var runIndices: [Int] = []
    
    public static let shared = LookupTableBuilder()
    private init() { }
    
    func create(_ size: PixelSize) -> Void {
        let buffer = LookupTableBuilder.makeBuffer(size)
        LookupTableBuilder.fill(buffer: buffer)
    }
    
    private static func fill(buffer: CVPixelBuffer) -> Void {
        let width = CVPixelBufferGetWidth(buffer)
        let height = CVPixelBufferGetHeight(buffer)
        CVPixelBufferLockBaseAddress(buffer, [])
        defer {
            CVPixelBufferUnlockBaseAddress(buffer, [])
        }
        
        let BGRAChannels = 4
        let count = width * height * BGRAChannels
        let ptr = CVPixelBufferGetBaseAddress(buffer)!
            .bindMemory(to: UInt8.self, capacity: count)
        for idx in 0..<count {
            ptr[idx] = 0
        }
    }
    
    private static func makeBuffer(_ coreSize: PixelSize) -> CVPixelBuffer {
        let bufferWidth = Int(3 * coreSize.width)
        let bufferHeight = Int(3 * coreSize.height)
        let format = kCVPixelFormatType_32BGRA
        let options: NSDictionary = [
            kCVPixelBufferCGImageCompatibilityKey: true,
            kCVPixelBufferMetalCompatibilityKey: true,
        ]
        var buffer: CVPixelBuffer!
        guard CVPixelBufferCreate(kCFAllocatorDefault, bufferWidth, bufferHeight, format, options, &buffer) == kCVReturnSuccess else {
            assertionFailure("Failed to create pixel buffer.")
            return buffer
        }
        return buffer
    }
}

/// Represents a point within the pattern's core.
/// Because patterns are small, we can use narrow integers.
struct StartPoint {
    let x: UInt8
    let y: UInt8
    
    public static let invalid = StartPoint(x: .max, y: .max)
}

/// Represents a series of points in the pattern's core.
/// Because runs are short, we can use narrow integers.
struct StartRun {
    /// Invalid negative values signal absence of a run.
    let tail: Int8
    let head: Int8
    
    let from: ChainDirection.RawValue
    let to: ChainDirection.RawValue
    
    public static let invalid = StartRun(tail: -1, head: -1, from: .max, to: .max)
}
