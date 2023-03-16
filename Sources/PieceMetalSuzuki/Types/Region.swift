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
    var runsCount: Int
    
    let patternSize: PatternSize

    init(size: PixelSize, gridPos: GridPosition, runsCount: Int, patternSize: PatternSize) {
        self.size = size
        self.gridPos = gridPos
        self.runsCount = runsCount
        self.patternSize = patternSize
    }

    /// Get run indices, given the present image size and grid size.
    func runIndices(imageSize: PixelSize, gridSize: PixelSize) -> Range<Int> {
        let base = baseOffset(imageSize: imageSize, gridSize: gridSize, regionSize: self.size, gridPos: self.gridPos, patternSize: patternSize)
        return Int(base)..<(Int(base) + runsCount)
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
                var validCount = 0
                for offset in 0..<patternSize.tableWidth {
                    if runBuffer.array[bufferBase + offset].isValid {
                        validCount += 1
                    } else {
                        break
                    }
                }
                
                /// Cannot use subscript notation to set uninitialized memory.
                /// https://forums.swift.org/t/how-to-initialize-array-of-class-instances-using-a-buffer-of-uninitialised-memory/39174/5
                buffer.baseAddress!.advanced(by: col).initialize(to: Region(
                    size: patternSize.coreSize,
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
