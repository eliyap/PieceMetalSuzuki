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
 */
internal final class LookupTableBuilder {
    
    let patternSize: PatternSize
    
    /// Contains distinct series of points.
    var pointTable: OrderedSet<[StartPoint]> = []
    var pointIndices: [UInt16] = []
    
    /// Contains distinct series of runs.
    var runTable: OrderedSet<[StartRun]> = []
    var runIndices: [UInt16] = []
    
    public init(patternSize: PatternSize) {
        self.patternSize = patternSize
        let buffer = BGRAPixelBuffer(coreSize: patternSize.coreSize)
        
        /// Setup.
        let device = MTLCreateSystemDefaultDevice()!
        let commandQueue = device.makeCommandQueue()!
        var metalTextureCache: CVMetalTextureCache!
        CVMetalTextureCacheCreate(kCFAllocatorDefault, nil, device, nil, &metalTextureCache)
        
        let count = CVPixelBufferGetWidth(buffer.buffer) * CVPixelBufferGetHeight(buffer.buffer) * BGRAChannels
        guard
            let pointBuffer = Buffer<PixelPoint>(device: device, count: count),
            let runBuffer = Buffer<Run>(device: device, count: count),
            let pointsUnfilled = Buffer<PixelPoint>(device: device, count: count),
            let runsUnfilled = Buffer<Run>(device: device, count: count)
        else {
            assert(false, "Failed to create buffer.")
            return
        }
        
        let starterSize = PatternSize.w1h1
        let iterations = 0..<patternSize.lutHeight
        for iteration in iterations {
            buffer.setPattern(coreSize: patternSize.coreSize, iteration: iteration)
            let texture = makeTextureFromCVPixelBuffer(pixelBuffer: buffer.buffer, textureFormat: .bgra8Unorm, textureCache: metalTextureCache)!
            
            createChainStarters(device: device, commandQueue: commandQueue, texture: texture, runBuffer: runBuffer, pointBuffer: pointBuffer)
            var grid = Grid(
                imageSize: PixelSize(width: UInt32(texture.width), height: UInt32(texture.height)),
                regions: SuzukiProfiler.time(.initRegions) {
                    return initializeRegions(runBuffer: runBuffer, texture: texture, patternSize: starterSize)
                },
                patternSize: starterSize
            )
            
            let (region, runs, points) = grid.combineAllForLUT(
                coreSize: patternSize.coreSize,
                device: device,
                pointsFilled: pointBuffer,
                runsFilled: runBuffer,
                pointsUnfilled: pointsUnfilled,
                runsUnfilled: runsUnfilled,
                commandQueue: commandQueue
            )

            assert(runs.count <= patternSize.tableWidth)
            let startRuns = (0..<patternSize.tableWidth).map { runIdx in
                if runs.indices.contains(runIdx) {
                    let run = runs[runIdx]
                    let base = Int32(baseOffset(grid: grid, region: region))
                    return StartRun(
                        tail: Int8(run.oldTail - base),
                        head: Int8(run.oldHead - base),
                        from: run.tailTriadFrom,
                        to: run.headTriadTo
                    )
                } else {
                    return .invalid
                }
            }
            runTable.append(startRuns)
            runIndices.append(UInt16(runTable.firstIndex(of: startRuns)!))

            assert(points.count <= patternSize.tableWidth)
            let startPoints = (0..<patternSize.tableWidth).map { pointIdx in
                if points.indices.contains(pointIdx) {
                    let point = points[pointIdx]
                    return StartPoint(
                        x: UInt8(point.x - patternSize.coreSize.width),
                        y: UInt8(point.y - patternSize.coreSize.height)
                    )
                } else {
                    return .invalid
                }
            }
            pointTable.append(startPoints)
            pointIndices.append(UInt16(pointTable.firstIndex(of: startPoints)!))
            
            if (iteration.isMultiple(of: 10000)) {
                print(iteration)
            }
        }

        /// Report.
        debugPrint("\(runTable.count) distinct runs")
        debugPrint("\(pointTable.count) distinct points")
    }
    
    public func setBuffers() -> Void {
        StartPoint.lookupTable = pointTable.reduce([], +)
        StartPoint.lookupTableIndices = pointIndices
        StartRun.lookupTable = runTable.reduce([], +)
        StartRun.lookupTableIndices = runIndices
    }
}

fileprivate let BGRAChannels = 4
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
            .bindMemory(to: UInt8.self, capacity: bufferWidth * bufferHeight * BGRAChannels)

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
            ptr[idx*BGRAChannels+0] = .zero
            ptr[idx*BGRAChannels+1] = .zero
            ptr[idx*BGRAChannels+2] = .zero
            ptr[idx*BGRAChannels+3] = 255
        }
    }
    
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
