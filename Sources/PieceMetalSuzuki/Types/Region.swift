//
//  Region.swift
//  
//
//  Created by Secret Asian Man Dev on 12/2/23.
//

import Foundation
import Metal

/**
 A CPU only struct used to organize Runs.
 Class allows easy in-place manipulation.
 
 Concentually represents one rectangle in the `Grid`.
 Purpose is to be merged with a vertically or horizontally joining `Region`,
 until the entire `Grid` is one `Region`.
 
 The memory location of the runs in this region is derived from information in this class and the grid structure.
 */
internal final class Region {
    /// Pixel size of the region.
    /// May be smaller than `Grid.gridSize` is this region covers the bottom or right edge of the image.
    var size: PixelSize
    
    /// Region's index in the grid.
    /// Changes as the number of regions grows smaller.
    var gridPos: GridPosition

    /// Number of runs in this region.
    var runsCount: UInt32
    
    let patternSize: PatternSize

    init(gridPos: GridPosition, runsCount: UInt32, patternSize: PatternSize) {
        self.size = patternSize.coreSize
        self.gridPos = gridPos
        self.runsCount = runsCount
        self.patternSize = patternSize
    }

    /// Get run indices, given the present image size and grid size.
    func runIndices(imageSize: PixelSize, gridSize: PixelSize) -> Range<Int> {
        let base = baseOffset(imageSize: imageSize, gridSize: gridSize, regionSize: self.size, gridPos: self.gridPos, patternSize: self.patternSize)
        return Int(base)..<(Int(base + runsCount))
    }
}

extension Region: CustomStringConvertible {
    var description: String {
        return "Region(size: \(size), gridPos: \(gridPos), \(runsCount) runs)"
    }
}

/**
 After using a metal kernel to deposit triad information in each pixel of `texture`,
 we start the algorithm with `Region`s whose size matches the lookup table pattern size.
 
 This uses 2 optimizations when creating rows.
 - reserves uninitialized capacity
 - initializes capacity in parallel
 */
func initializeRegions(
    runBuffer: Buffer<Run>,
    texture: MTLTexture,
    patternSize: PatternSize
) -> [[Region]] {
    let coreWidth = Int(patternSize.coreSize.width)
    let coreHeight = Int(patternSize.coreSize.height)
    
    /// Divide pixel width by core width, rounding up.
    let regionTableWidth = texture.width.dividedByRoundingUp(divisor: coreWidth)
    let regionTableHeight = texture.height.dividedByRoundingUp(divisor: coreHeight)
    
    var regions: [[Region]] = []
    for row in 0..<regionTableHeight {
        let regionRow = [Region](unsafeUninitializedCapacity: regionTableWidth) { buffer, initializedCount in
            DispatchQueue.concurrentPerform(iterations: regionTableWidth) { col in
                /// Count valid elements in each 1x1 region.
                let bufferBase = ((row * regionTableWidth) + col) * Int(patternSize.tableWidth)
                var validCount = UInt32.zero
                for offset in 0..<Int(patternSize.tableWidth) {
                    if runBuffer.array[bufferBase + offset].isValid {
                        validCount += 1
                    } else {
                        break
                    }
                }
                
                /// Cannot use subscript notation to set uninitialized memory.
                /// https://forums.swift.org/t/how-to-initialize-array-of-class-instances-using-a-buffer-of-uninitialised-memory/39174/5
                buffer.baseAddress!.advanced(by: col).initialize(to: Region(
                    gridPos: GridPosition(row: UInt32(row), col: UInt32(col)),
                    runsCount: validCount,
                    patternSize: patternSize
                ))
            }
            initializedCount = regionTableWidth
        }
        regions.append(regionRow)
    }
    return regions
}

// @metal
internal struct GridSize {
    public let width: UInt32
    public let height: UInt32
}

// @metal 
internal struct RegionGPU {
    let size: PixelSize
    let gridPos: GridPosition
    let runsCount: UInt32
    let patternSize: PatternSize
}

func initializeRegionsGPU(
    device: MTLDevice,
    commandQueue: MTLCommandQueue,
    runBuffer: Buffer<Run>,
    texture: MTLTexture,
    patternSize: PatternSize
) -> [[Region]]? {
    guard
        let kernelFunction = loadMetalFunction(filename: "Region", functionName: "initializeRegions", device: device),
        let pipelineState = try? device.makeComputePipelineState(function: kernelFunction),
        let cmdBuffer = commandQueue.makeCommandBuffer(),
        let cmdEncoder = cmdBuffer.makeComputeCommandEncoder()
    else {
        assert(false, "Failed to setup pipeline.")
        return nil
    }
    
    /// Divide pixel width by core width, rounding up.
    var gridSize = GridSize(
        width: UInt32(texture.width).dividedByRoundingUp(divisor: patternSize.coreSize.width),
        height: UInt32(texture.height).dividedByRoundingUp(divisor: patternSize.coreSize.height)
    )
    var patternSize = patternSize
    
    return withAutoRelease { token in 
        guard let regionBuffer = Buffer<RegionGPU>(
            device: device,
            count: Int(gridSize.width * gridSize.height),
            token: token
        ) else {
            assert(false, "Failed to allocate region buffer.")
            return nil
        }

        cmdEncoder.setComputePipelineState(pipelineState)
        cmdEncoder.setBytes(&gridSize, length: MemoryLayout<GridSize>.size, index: 0)
        cmdEncoder.setBytes(&patternSize, length: MemoryLayout<PatternSize>.size, index: 1)
        cmdEncoder.setBuffer(runBuffer.mtlBuffer, offset: 0, index: 2)
        cmdEncoder.setBuffer(regionBuffer.mtlBuffer, offset: 0, index: 3)
        
        /// Subdivide grid as far as possible.
        /// https://developer.apple.com/documentation/metal/mtlcomputecommandencoder/1443138-dispatchthreadgroups
        let tgPerGrid = MTLSizeMake(
            Int(gridSize.width).dividedByRoundingUp(divisor: pipelineState.threadExecutionWidth),
            Int(gridSize.height).dividedByRoundingUp(divisor: pipelineState.threadHeight),
            1
        )
        
        cmdEncoder.dispatchThreadgroups(tgPerGrid, threadsPerThreadgroup: pipelineState.maxThreads)
        cmdEncoder.endEncoding()
        cmdBuffer.commit()
        cmdBuffer.waitUntilCompleted()
        
        var result: [[Region]] = []
        for row in 0..<Int(gridSize.height) {
            let regionRow = [Region](unsafeUninitializedCapacity: Int(gridSize.width)) { buffer, initializedCount in
                for col in 0..<Int(gridSize.width) {
                    let region = regionBuffer.array[(row * Int(gridSize.width)) + col]
                    buffer.baseAddress!.advanced(by: col).initialize(to: Region(
                        gridPos: region.gridPos,
                        runsCount: region.runsCount,
                        patternSize: region.patternSize
                    ))
                }
                initializedCount = Int(gridSize.width)
            }
            result.append(regionRow)
        }
        return result
    }
}
