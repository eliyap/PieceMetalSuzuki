//
//  LookupTableBuilder.swift
//  
//
//  Created by Secret Asian Man Dev on 15/2/23.
//

import Foundation
import CoreVideo
import OrderedCollections

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
 Hence, the 3x3 lookup table has 4 columns.
 */
internal final class LookupTableBuilder {
    
    let coreSize: PixelSize
    
    /// Contains distinct series of points.
    var pointTable: OrderedSet<[StartPoint]> = []
    var pointIndices: [Int] = []
    
    /// Contains distinct series of runs.
    var runTable: OrderedSet<[StartRun]> = []
    var runIndices: [Int] = []
    
    public static var shared: LookupTableBuilder! = nil
    public init(_ coreSize: PixelSize) {
        self.coreSize = coreSize
        let buffer = BGRAPixelBuffer(coreSize: coreSize)
        
        /// Setup.
        let device = MTLCreateSystemDefaultDevice()!
        let commandQueue = device.makeCommandQueue()!
        let runLUTBuffer = Run.LUTBuffer!
        let pointLUTBuffer = PixelPoint.LUTBuffer!
        var metalTextureCache: CVMetalTextureCache!
        CVMetalTextureCacheCreate(kCFAllocatorDefault, nil, device, nil, &metalTextureCache)
        
        let iterations = 0..<(2 << Int((coreSize.height + 2) * (coreSize.width + 2)))
        for iteration in iterations {
            buffer.setPattern(coreSize: coreSize, iteration: iteration)
            let texture = makeTextureFromCVPixelBuffer(pixelBuffer: buffer.buffer, textureFormat: .bgra8Unorm, textureCache: metalTextureCache)!
            let (pointBuffer, runBuffer) = createChainStarters(device: device, commandQueue: commandQueue, texture: texture, runLUTBuffer: runLUTBuffer, pointLUTBuffer: pointLUTBuffer)!
            var grid = Grid(
                imageSize: PixelSize(width: UInt32(texture.width), height: UInt32(texture.height)),
                gridSize: PixelSize(width: 1, height: 1),
                regions: Profiler.time(.initRegions) {
                    return initializeRegions(runBuffer: runBuffer, texture: texture)
                }
            )
            
            let count = texture.width * texture.height * 4
            let pointsUnfilled = Buffer<PixelPoint>(device: device, count: count)!
            let runsUnfilled = Buffer<Run>(device: device, count: count)!
            
            let (region, runs, points) = grid.combineAllForLUT(
                coreSize: coreSize,
                device: device,
                pointsFilled: pointBuffer,
                runsFilled: runBuffer,
                pointsUnfilled: pointsUnfilled,
                runsUnfilled: runsUnfilled,
                commandQueue: commandQueue
            )

            let startRuns = runs.map { run in
                let base = Int32(baseOffset(grid: grid, region: region))
                return StartRun(
                    tail: Int8(run.oldTail - base),
                    head: Int8(run.oldHead - base),
                    from: run.tailTriadFrom,
                    to: run.headTriadTo
                )
            }
            runTable.append(startRuns)

            let startPoints = points.map { point in
                StartPoint(
                    x: UInt8(point.x - coreSize.width),
                    y: UInt8(point.y - coreSize.height)
                )
            }
            pointTable.append(startPoints)
            if (iteration.isMultiple(of: 10000)) {
                print(iteration)
            }
        }

        /// Report.
        debugPrint("\(runTable.count) distinct runs")
        debugPrint("\(pointTable.count) distinct points")

        saveBufferToPng(buffer: buffer.buffer, format: .BGRA8)
    }
}

/// Represents a point within the pattern's core.
/// Because patterns are small, we can use narrow integers.
struct StartPoint: Hashable {
    let x: UInt8
    let y: UInt8
    
    public static let invalid = StartPoint(x: .max, y: .max)
}

/// Represents a series of points in the pattern's core.
/// Because runs are short, we can use narrow integers.
struct StartRun: Hashable {
    /// Invalid negative values signal absence of a run.
    let tail: Int8
    let head: Int8
    
    let from: ChainDirection.RawValue
    let to: ChainDirection.RawValue
    
    public static let invalid = StartRun(tail: -1, head: -1, from: .max, to: .max)
}

internal final class BGRAPixelBuffer {
    
    var buffer: CVPixelBuffer
    var ptr: UnsafeMutablePointer<UInt8>

    private let bufferWidth: Int
    private let bufferHeight: Int
    
    init(coreSize: PixelSize) { 
        let bufferWidth = Int(3 * coreSize.width)
        let bufferHeight = Int(3 * coreSize.height)
        let format = kCVPixelFormatType_32BGRA
        let options: NSDictionary = [
            kCVPixelBufferCGImageCompatibilityKey: true,
            kCVPixelBufferMetalCompatibilityKey: true,
        ]
        var buffer: CVPixelBuffer!
        let status = CVPixelBufferCreate(kCFAllocatorDefault, bufferWidth, bufferHeight, format, options, &buffer)
        assert(status == kCVReturnSuccess)
        self.buffer = buffer

        CVPixelBufferLockBaseAddress(buffer, [])
        self.ptr = CVPixelBufferGetBaseAddress(buffer)!
            .bindMemory(to: UInt8.self, capacity: bufferWidth * bufferHeight * 4)

        var leftPixels: Int = 0
        var rightPixels: Int = 0
        var topPixels: Int = 0
        var bottomPixels: Int = 0
        CVPixelBufferGetExtendedPixels(buffer, &leftPixels, &rightPixels, &topPixels, &bottomPixels)
        assert(leftPixels == 0)
        assert(topPixels == 0)
//        self.bufferWidth = rightPixels + bufferWidth
//        self.bufferHeight = bottomPixels + bufferHeight
       self.bufferWidth = 16 // IDK
       self.bufferHeight = bottomPixels + bufferHeight

        fill()
        print("bufferWidth, bufferHeight", bufferWidth, bufferHeight)
    }

    deinit {
        CVPixelBufferUnlockBaseAddress(buffer, [])
    }

    private func fill() -> Void {
        let count = bufferWidth * bufferHeight
        for idx in 0..<count {
            ptr[idx*4+0] = .zero
            ptr[idx*4+1] = .zero
            ptr[idx*4+2] = .zero
            ptr[idx*4+3] = 255
        }
    }
    
    let BGRAChannels = 4
    func setPattern(coreSize: PixelSize, iteration: Int) -> Void {
        DispatchQueue.concurrentPerform(iterations: Int((coreSize.width + 2) * (coreSize.height + 2))) { bitNumber in
            var (row, col) = bitNumber.quotientAndRemainder(dividingBy: Int(coreSize.width + 2))
            row += Int(coreSize.height - 1)
            col += Int(coreSize.width - 1)
            
            let offset = (row * bufferWidth + col) * BGRAChannels
            if (iteration & (1 << bitNumber)) != 0 {
                ptr[offset+0] = .max
                ptr[offset+1] = .max
                ptr[offset+2] = .max
            } else {
                ptr[offset+0] = .zero
                ptr[offset+1] = .zero
                ptr[offset+2] = .zero
            }
        }
    }
}
