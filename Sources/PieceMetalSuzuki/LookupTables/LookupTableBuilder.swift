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
 */
internal final class LookupTableBuilder {
    
    let patternSize: PatternSize
    
    public typealias TableIndex = UInt16
    
    /// Contains distinct series of points.
    var pointTable: [[StartPoint]] = []
    var pointIndices: [TableIndex] = []
    
    /// Contains distinct series of runs.
    var runTable: [[StartRun]] = []
    var runIndices: [TableIndex] = []
    
    public init(patternSize: PatternSize) {
        self.patternSize = patternSize
        
        /// Setup.
        let device = MTLCreateSystemDefaultDevice()!
        
        let queue = DispatchQueue(label: "com.aruco.LookupTableBuilder", qos: .utility, attributes: [.concurrent])
        
        let iterations = 0..<(patternSize.lutHeight / 8)
        for batch in iterations {
            
            var startRuns1: [StartRun] = []
            var startPoints1: [StartPoint] = []
            var startRuns2: [StartRun] = []
            var startPoints2: [StartPoint] = []
            var startRuns3: [StartRun] = []
            var startPoints3: [StartPoint] = []
            var startRuns4: [StartRun] = []
            var startPoints4: [StartPoint] = []
            var startRuns5: [StartRun] = []
            var startPoints5: [StartPoint] = []
            var startRuns6: [StartRun] = []
            var startPoints6: [StartPoint] = []
            var startRuns7: [StartRun] = []
            var startPoints7: [StartPoint] = []
            var startRuns8: [StartRun] = []
            var startPoints8: [StartPoint] = []
            
            let group = DispatchGroup()
            withAutoRelease { [self] releaseToken in
                DispatchQueue.global(qos: .utility).async(group: group) {
                    (startRuns1, startPoints1) = findTableRow(iteration: batch * 8 + 0, device: device, releaseToken: releaseToken)
                }
                DispatchQueue.global(qos: .utility).async(group: group) {
                    (startRuns2, startPoints2) = findTableRow(iteration: batch * 8 + 1, device: device, releaseToken: releaseToken)
                }
                DispatchQueue.global(qos: .utility).async(group: group) {
                    (startRuns3, startPoints3) = findTableRow(iteration: batch * 8 + 2, device: device, releaseToken: releaseToken)
                }
                DispatchQueue.global(qos: .utility).async(group: group) {
                    (startRuns4, startPoints4) = findTableRow(iteration: batch * 8 + 3, device: device, releaseToken: releaseToken)
                }
                DispatchQueue.global(qos: .utility).async(group: group) {
                    (startRuns5, startPoints5) = findTableRow(iteration: batch * 8 + 4, device: device, releaseToken: releaseToken)
                }
                DispatchQueue.global(qos: .utility).async(group: group) {
                    (startRuns6, startPoints6) = findTableRow(iteration: batch * 8 + 5, device: device, releaseToken: releaseToken)
                }
                DispatchQueue.global(qos: .utility).async(group: group) {
                    (startRuns7, startPoints7) = findTableRow(iteration: batch * 8 + 6, device: device, releaseToken: releaseToken)
                }
                DispatchQueue.global(qos: .utility).async(group: group) {
                    (startRuns8, startPoints8) = findTableRow(iteration: batch * 8 + 7, device: device, releaseToken: releaseToken)
                }
            }
            
            group.wait()
            
            for (startRuns, startPoints) in [
                (startRuns1, startPoints1),
                (startRuns2, startPoints2),
                (startRuns3, startPoints3),
                (startRuns4, startPoints4),
                (startRuns5, startPoints5),
                (startRuns6, startPoints6),
                (startRuns7, startPoints7),
                (startRuns8, startPoints8)
            ] {
                /// Insert row.
                if let rowIdx = runTable.firstIndex(of: startRuns) {
                    runIndices.append(TableIndex(rowIdx))
                } else {
                    runIndices.append(TableIndex(runTable.count))
                    runTable.append(startRuns)
                }
                
                /// Insert row.
                if let rowIdx = pointTable.firstIndex(of: startPoints) {
                    pointIndices.append(TableIndex(rowIdx))
                } else {
                    pointIndices.append(TableIndex(pointTable.count))
                    pointTable.append(startPoints)
                }
            }
        }
        
        /// Report.
        debugPrint("\(runTable.count) distinct runs")
        debugPrint("\(pointTable.count) distinct points")
        let validRunCount = runTable
            .map { row in row.filter { $0 != .invalid }.count }
            .reduce(0, +)
        debugPrint("\(validRunCount) / \(runTable.count * runTable[0].count) valid runs")
    }
    
    func findTableRow(iteration: Int, device: MTLDevice, releaseToken: AutoReleasePoolToken) -> ([StartRun], [StartPoint]) {
        let buffer = BGRAPixelBuffer(coreSize: patternSize.coreSize)
        let count = CVPixelBufferGetWidth(buffer.buffer) * CVPixelBufferGetHeight(buffer.buffer) * BGRAChannels
            
        let commandQueue = device.makeCommandQueue()!
        var metalTextureCache: CVMetalTextureCache!
        CVMetalTextureCacheCreate(kCFAllocatorDefault, nil, device, nil, &metalTextureCache)
        
        let starterSize = PatternSize.w1h1
        
        guard
            let pointsFilled = Buffer<PixelPoint>(device: device, count: count, token: releaseToken),
            let runsFilled = Buffer<Run>(device: device, count: count, token: releaseToken)
        else {
            fatalError("Failed to create buffer.")
        }
        
        guard let kernelFunction = loadMetalFunction(filename: "PieceSuzukiKernel", functionName: "startChain", device: device) else {
            fatalError("Failed to load function.")
        }
            
        buffer.setPattern(coreSize: patternSize.coreSize, iteration: iteration)
        CVMetalTextureCacheFlush(metalTextureCache, 0)
        let texture = makeTextureFromCVPixelBuffer(pixelBuffer: buffer.buffer, textureFormat: .bgra8Unorm, textureCache: metalTextureCache)!
        
        createChainStarters(device: device, function: kernelFunction, commandQueue: commandQueue, texture: texture, runBuffer: runsFilled, pointBuffer: pointsFilled, releaseToken: releaseToken)
        var grid = Grid(
            imageSize: PixelSize(width: UInt32(texture.width), height: UInt32(texture.height)),
            regions: initializeRegions(runBuffer: runsFilled, texture: texture, patternSize: starterSize),
            patternSize: starterSize
        )
        
        let (region, runs, points) = grid.combineAllForLUT(
            coreSize: patternSize.coreSize,
            pointsFilled: pointsFilled.array,
            runsFilled: runsFilled.array
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
        
        if (iteration.isMultiple(of: 10000)) {
            print(iteration)
        }
        
        return (startRuns, startPoints)
    }
    
    internal func setBuffers() -> Void {
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
