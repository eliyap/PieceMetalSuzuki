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
class Region {
    let origin: PixelPoint
    
    /// Spatial size of the grid, which may be smaller at the trailing and bottom edges.
    var size: PixelSize
    
    var gridPos: GridPosition

    /// Number of elements in the region.
    var runsCount: UInt32

    init(origin: PixelPoint, size: PixelSize, gridPos: GridPosition, runsCount: UInt32) {
        self.origin = origin
        self.size = size
        self.gridPos = gridPos
        self.runsCount = runsCount
    }

    /// Get run indices, given the present image size and grid size.
    func runIndices(imageSize: PixelSize, gridSize: PixelSize) -> [Int] {
        let base = baseOffset(imageSize: imageSize, gridSize: gridSize, regionSize: self.size, gridPos: self.gridPos)
        return (0..<runsCount).map { idx in
            Int(base + idx)
        }
    }
}

extension Region: CustomStringConvertible {
    var description: String {
        return "Region(origin: \(origin), size: \(size), gridPos: \(gridPos), \(runsCount) runs)"
    }
}

func initializeRegions(
    runBuffer: Buffer<Run>,
    texture: MTLTexture
) -> [[Region]] {
    var regions: [[Region]] = []
    for row in 0..<texture.height {
        let regionRow = [Region](unsafeUninitializedCapacity: texture.width) { buffer, initializedCount in
            DispatchQueue.concurrentPerform(iterations: texture.width) { col in
                /// Count valid elements in each 1x1 region.
                let bufferBase = ((row * texture.width) + col) * 4
                var validCount = UInt32.zero
                for offset in 0..<4 {
                    if runBuffer.array[bufferBase + offset].isValid {
                        validCount += 1
                    } else {
                        break
                    }
                }
                
                buffer.baseAddress!.advanced(by: col).initialize(to: Region(
                    origin: PixelPoint(x: UInt32(col), y: UInt32(row)),
                    size: PixelSize(width: 1, height: 1),
                    gridPos: GridPosition(row: UInt32(row), col: UInt32(col)),
                    runsCount: validCount
                ))
            }
            initializedCount = texture.width
        }
        regions.append(regionRow)
    }
    return regions
}
