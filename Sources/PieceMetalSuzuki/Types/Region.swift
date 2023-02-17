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
    /// Location of the pixel's top left corner in the image.
    let origin: PixelPoint
    
    /// Pixel size of the region.
    /// May be smaller than `Grid.gridSize` is this region covers the bottom or right edge of the image.
    var size: PixelSize
    
    /// Region's index in the grid.
    /// Changes as the number of regions grows smaller.
    var gridPos: GridPosition

    /// Number of runs in this region.
    var runsCount: UInt32
    
    let pointsPerPixel: UInt32

    init(origin: PixelPoint, size: PixelSize, gridPos: GridPosition, runsCount: UInt32, pointsPerPixel: UInt32) {
        self.origin = origin
        self.size = size
        self.gridPos = gridPos
        self.runsCount = runsCount
        self.pointsPerPixel = pointsPerPixel
    }

    /// Get run indices, given the present image size and grid size.
    func runIndices(imageSize: PixelSize, gridSize: PixelSize) -> Range<Int> {
        let base = baseOffset(imageSize: imageSize, gridSize: gridSize, regionSize: self.size, gridPos: self.gridPos, pointsPerPixel: pointsPerPixel)
        return Int(base)..<Int(base + runsCount)
    }
}

extension Region: CustomStringConvertible {
    var description: String {
        return "Region(origin: \(origin), size: \(size), gridPos: \(gridPos), \(runsCount) runs)"
    }
}

/**
 After using a metal kernel to deposit triad information in each pixel of `texture`,
 we start the algorithm with the smallest possible region: a 1x1 covering just one pixel.
 
 This uses 2 optimizations when creating rows.
 - reserves uninitialized capacity
 - initializes capacity in parallel
 */
func initializeRegions(
    runBuffer: Buffer<Run>,
    texture: MTLTexture,
    pointsPerPixel: UInt32 = 4
) -> [[Region]] {
    var regions: [[Region]] = []
    for row in 0..<texture.height {
        let regionRow = [Region](unsafeUninitializedCapacity: texture.width) { buffer, initializedCount in
            DispatchQueue.concurrentPerform(iterations: texture.width) { col in
                /// Count valid elements in each 1x1 region.
                let bufferBase = ((row * texture.width) + col) * Int(pointsPerPixel)
                var validCount = UInt32.zero
                for offset in 0..<Int(pointsPerPixel) {
                    if runBuffer.array[bufferBase + offset].isValid {
                        validCount += 1
                    } else {
                        break
                    }
                }
                
                /// Cannot use subscript notation to set uninitialized memory.
                /// https://forums.swift.org/t/how-to-initialize-array-of-class-instances-using-a-buffer-of-uninitialised-memory/39174/5
                buffer.baseAddress!.advanced(by: col).initialize(to: Region(
                    origin: PixelPoint(x: UInt32(col), y: UInt32(row)),
                    size: PixelSize(width: 1, height: 1),
                    gridPos: GridPosition(row: UInt32(row), col: UInt32(col)),
                    runsCount: validCount,
                    pointsPerPixel: pointsPerPixel
                ))
            }
            initializedCount = texture.width
        }
        regions.append(regionRow)
    }
    return regions
}

func initializeRegions_LUT(
    runBuffer: Buffer<Run>,
    texture: MTLTexture,
    coreSize: PixelSize,
    tableWidth: Int,
    pointsPerPixel: UInt32
) -> [[Region]] {
    let coreWidth = Int(coreSize.width)
    let coreHeight = Int(coreSize.height)
    let regionTableWidth = (texture.width + coreWidth - 1) / coreWidth
    let regionTableHeight = (texture.height + coreHeight - 1) / coreHeight
    
    var regions: [[Region]] = []
    for row in 0..<regionTableHeight {
        let regionRow = [Region](unsafeUninitializedCapacity: regionTableWidth) { buffer, initializedCount in
            DispatchQueue.concurrentPerform(iterations: regionTableWidth) { col in
                /// Count valid elements in each 1x1 region.
                let bufferBase = ((row * regionTableWidth) + col) * tableWidth
                var validCount = UInt32.zero
                for offset in 0..<tableWidth {
                    if runBuffer.array[bufferBase + offset].isValid {
                        validCount += 1
                    } else {
                        break
                    }
                }
                
                /// Cannot use subscript notation to set uninitialized memory.
                /// https://forums.swift.org/t/how-to-initialize-array-of-class-instances-using-a-buffer-of-uninitialised-memory/39174/5
                buffer.baseAddress!.advanced(by: col).initialize(to: Region(
                    origin: PixelPoint(x: UInt32(col), y: UInt32(row)),
                    size: coreSize,
                    gridPos: GridPosition(row: UInt32(row), col: UInt32(col)),
                    runsCount: validCount,
                    pointsPerPixel: pointsPerPixel
                ))
            }
            initializedCount = regionTableWidth
        }
        regions.append(regionRow)
    }
    return regions
}
