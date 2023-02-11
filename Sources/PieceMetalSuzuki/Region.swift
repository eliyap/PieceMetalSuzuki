import Foundation
import Metal

struct PixelSize: Equatable, CustomStringConvertible {
    let width: UInt32
    let height: UInt32

    var description: String {
        return "w\(width)h\(height)"
    }
}

/// Indicates where a `Region` is within the `Grid`.
struct GridPosition: CustomStringConvertible {
    var row: UInt32
    var col: UInt32
    var description: String {
        return "gr\(row)gc\(col)"
    }
}

/// A CPU only struct used to organize Runs.
/// Class allows easy in-place manipulation.
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

struct Grid {
    let imageSize: PixelSize
    
    /// Assumed region size. Actual region size is smaller at the bottom and trailing edges.
    var gridSize: PixelSize
    
    var regions: [[Region]]
    
    enum ReduceDirection {
        case horizontal, vertical
        mutating func flip() {
            switch self {
            case .horizontal: self = .vertical
            case .vertical: self = .horizontal
            }
        }
    }
    
    mutating func combineAll(
        device: MTLDevice,
        pointsHorizontal: Buffer<PixelPoint>,
        runsHorizontal: Buffer<Run>,
        commandQueue: MTLCommandQueue
    ) -> Void {
        guard 
            let pointsVertical = Buffer<PixelPoint>(device: device, count: pointsHorizontal.count),
            let runsVertical = Buffer<Run>(device: device, count: runsHorizontal.count)
        else {
            assert(false, "Failed to create buffer.")
            return
        }
        
        var dxn = ReduceDirection.vertical
        while (regions.count > 1) || (regions[0].count > 1) {
            let srcBuffer: Buffer<PixelPoint>
            let dstBuffer: Buffer<PixelPoint>
            let srcPts: UnsafeMutablePointer<PixelPoint>
            let dstPts: UnsafeMutablePointer<PixelPoint>
            let srcRuns: UnsafeMutablePointer<Run>
            let dstRuns: UnsafeMutablePointer<Run>
            
            let numRows = regions.count
            let numCols = regions[0].count
            
            var blitRunIndices: [Int] = []
            
            switch dxn {
            case .horizontal:
                (srcBuffer, dstBuffer) = (runsVertical, runsHorizontal)
                (srcRuns, dstRuns) = (runsVertical.array, runsHorizontal.array)
                (srcPts, dstPts) = (pointsVertical.array, pointsHorizontal.array)

                if numCols.isMultiple(of: 2) == false {
                    /// Request last column blit.
                    for row in regions {
                        let region = row.last!
                        for runIdx in region.runIndices(imageSize: imageSize, gridSize: gridSize) {
                            dstRuns[runIdx] = srcRuns[runIdx]
                            srcRuns[runIdx].newTail = srcRuns[runIdx].oldTail
                            srcRuns[runIdx].newHead = srcRuns[runIdx].oldHead
                        }
                        blitRunIndices += region.runIndices(imageSize: imageSize, gridSize: gridSize)
                    }
                }
                
                let newGridSize = PixelSize(width: gridSize.width * 2, height: gridSize.height)
                for rowIdx in 0..<numRows {
                    for colIdx in stride(from: 0, to: numCols - 1, by: 2).reversed() {
                        let a = regions[rowIdx][colIdx]
                        let b = regions[rowIdx].remove(at: colIdx + 1)
                        let newRequests = combine(a: a, b: b,
                                dxn: dxn, newGridSize: newGridSize,
                                srcPts: srcPts, srcRuns: srcRuns,
                                dstPts: dstPts, dstRuns: dstRuns)
                        blitRunIndices += newRequests
                    }
                    /// Update grid position for remaining regions.
                    for region in regions[rowIdx] {
                        region.gridPos.col /= 2
                    }
                }
                gridSize = newGridSize
            
            case .vertical:
                (srcBuffer, dstBuffer) = (runsHorizontal, runsVertical)
                (srcRuns, dstRuns) = (runsHorizontal.array, runsVertical.array)
                (srcPts, dstPts) = (pointsHorizontal.array, pointsVertical.array)

                if numRows.isMultiple(of: 2) == false {
                    /// Request last column blit.
                    for region in regions.last! {
                        for runIdx in region.runIndices(imageSize: imageSize, gridSize: gridSize) {
                            dstRuns[runIdx] = srcRuns[runIdx]
                            srcRuns[runIdx].newTail = srcRuns[runIdx].oldTail
                            srcRuns[runIdx].newHead = srcRuns[runIdx].oldHead
                        }
                        blitRunIndices += region.runIndices(imageSize: imageSize, gridSize: gridSize)
                    }
                }
                
                let newGridSize = PixelSize(width: gridSize.width, height: gridSize.height * 2)
                for rowIdx in stride(from: 0, to: numRows - 1, by: 2).reversed() {
                    for colIdx in 0..<numCols {
                        let a = regions[rowIdx][colIdx]
                        let b = regions[rowIdx+1][colIdx]
                        let newRequests = combine(a: a, b: b,
                                dxn: dxn, newGridSize: newGridSize,
                                srcPts: srcPts, srcRuns: srcRuns,
                                dstPts: dstPts, dstRuns: dstRuns)
                        blitRunIndices += newRequests
                        
                    }
                    /// Remove entire row at once.
                    regions.remove(at: rowIdx + 1)
                }
                /// Update grid position for remaining regions.
                for rowIdx in 0..<regions.count {
                    for colIdx in 0..<numCols {
                        regions[rowIdx][colIdx].gridPos.row /= 2
                    }
                }
                gridSize = newGridSize
            }
            
            cpuBlit(runIndices: blitRunIndices, srcPts: srcPts, srcRuns: srcRuns, dstPts: dstPts)
            
            #if SHOW_GRID_WORK
            for reg in regions.joined() {
                dump(region: reg, points: dstPts, runs: dstRuns)
            }
            #endif
            
            dxn.flip()
        }
        
        /// Return final results.
        let pointBuffer: UnsafeMutablePointer<PixelPoint>
        let runBuffer: UnsafeMutablePointer<Run>
        
        switch dxn {
        case .horizontal:
            pointBuffer = pointsHorizontal.array
            runBuffer = runsHorizontal.array
        case .vertical:
            pointBuffer = pointsVertical.array
            runBuffer = runsVertical.array
        }
        
        #if DEBUG
        for runIdx in regions[0][0].runIndices(imageSize: imageSize, gridSize: gridSize) {
            let run = runBuffer[runIdx]
//            print((run.oldTail..<run.oldHead).map { pointBuffer[Int($0)] })
            assert(run.isValid)
        }
        print("Found \(regions[0][0].runsCount) contours.")
        #endif
        
        // return regions[0][0]
    }
    
    #if SHOW_GRID_WORK
    func dump(region: Region, points: UnsafeMutablePointer<PixelPoint>, runs: UnsafeMutablePointer<Run>) {
        let baseOffset = baseOffset(grid: self, region: region)
        debugPrint("[DUMP]: \(region)")
        for offset in 0..<Int(region.runsCount) {
            let runBufferOffset = Int(offset + Int(baseOffset))
            let run = runs[runBufferOffset]
            assert(run.isValid)
            
            let chain = (run.oldTail..<run.oldHead).map { points[Int($0)] }
            debugPrint("- \(run) \(chain) @\(runBufferOffset)(\(baseOffset)+\(offset))")
        }
    }
    #endif
    
    func combine(
        a: Region, b: Region,
        dxn: ReduceDirection, newGridSize: PixelSize,
        srcPts: UnsafeMutablePointer<PixelPoint>, srcRuns: UnsafeMutablePointer<Run>,
        dstPts: UnsafeMutablePointer<PixelPoint>, dstRuns: UnsafeMutablePointer<Run>
    ) -> [Int] {
        #if SHOW_GRID_WORK
        debugPrint("Combining \(a) and \(b)")
        debugPrint("imgSize: \(imageSize), gridSize: \(gridSize)")
        #endif
        let aBaseOffset: UInt32 = baseOffset(grid: self, region: a)
        let bBaseOffset: UInt32 = baseOffset(grid: self, region: b)
        
        let newRegionSize: PixelSize
        switch dxn {
        case .vertical:
            let bottomEdge = ((a.gridPos.row / 2) + 1) * newGridSize.height
            let newRegionHeight = bottomEdge > imageSize.height
                ? imageSize.height - (a.gridPos.row / 2) * newGridSize.height
                : newGridSize.height
            newRegionSize = PixelSize(
                width: a.size.width,
                height: newRegionHeight
            )
        case .horizontal:
            let rightEdge = ((a.gridPos.col / 2) + 1) * newGridSize.width
            let newRegionWidth = rightEdge > imageSize.width
                ? imageSize.width - (a.gridPos.col / 2) * newGridSize.width
                : newGridSize.width
            newRegionSize = PixelSize(
                width: newRegionWidth,
                height: a.size.height
            )
        }
        
        let newBaseOffset: UInt32
        switch dxn {
        case .vertical:
            newBaseOffset = baseOffset(imageSize: imageSize, gridSize: newGridSize, regionSize: newRegionSize, gridPos: GridPosition(row: a.gridPos.row / 2, col: a.gridPos.col))
        case .horizontal:
            newBaseOffset = baseOffset(imageSize: imageSize, gridSize: newGridSize, regionSize: newRegionSize, gridPos: GridPosition(row: a.gridPos.row, col: a.gridPos.col / 2))
        }

        var aRunIndices = (0..<Int(a.runsCount)).map { $0 + Int(aBaseOffset) }
        var bRunIndices = (0..<Int(b.runsCount)).map { $0 + Int(bBaseOffset) }

        var nextPointOffset = Int32.zero
        var nextRunOffset = UInt32.zero
        
        func headPoint(for runIdx: Int) -> PixelPoint {
            srcPts[Int(srcRuns[runIdx].oldHead - 1)]
        }
        func tailPoint(for runIdx: Int) -> PixelPoint {
            srcPts[Int(srcRuns[runIdx].oldTail)]
        }

        // Find run, if any, whose tail matches the head at this point, pointing in this direction.
        func findTailForHead(point: PixelPoint, direction: ChainDirection) -> Int? {
            precondition(direction != .closed)

            /// For the given head pointer, describe the corresponding tail pointer.
            let tail: PixelPoint = point[direction]
            let from = direction.inverse.rawValue
            func tailDoesMatch(idx: Int) -> Bool {
                return tail == tailPoint(for: idx) && srcRuns[idx].tailTriadFrom == from
            }
            if let aIdxIdx = aRunIndices.firstIndex(where: tailDoesMatch) {
                let aRunIdx = aRunIndices.remove(at: aIdxIdx)
                return aRunIdx
            }
            if let bIdxIdx = bRunIndices.firstIndex(where: tailDoesMatch) {
                let bRunIdx = bRunIndices.remove(at: bIdxIdx)
                return bRunIdx
            }
            return nil
        }

        func findHeadForTail(point: PixelPoint, direction: ChainDirection) -> Int? {
            precondition(direction != .closed)

            /// For the given tail pointer, describe the corresponding head pointer.
            let head: PixelPoint = point[direction]
            let to = direction.inverse.rawValue
            func headDoesMatch(idx: Int) -> Bool {
                return head == headPoint(for: idx) && srcRuns[idx].headTriadTo == to
            }
            if let aIdxIdx = aRunIndices.firstIndex(where: headDoesMatch) {
                let aRunIdx = aRunIndices.remove(at: aIdxIdx)
                return aRunIdx
            }
            if let bIdxIdx = bRunIndices.firstIndex(where: headDoesMatch) {
                let bRunIdx = bRunIndices.remove(at: bIdxIdx)
                return bRunIdx
            }
            return nil
        }

        func join(runIdx: Int) -> Void {
            precondition(srcRuns[runIdx].isValid)
            var joinedRunsIndices: [Int] = [runIdx]
            
            var headPt = headPoint(for: runIdx)
            var headDxn = srcRuns[runIdx].headTriadTo
            while
                headDxn != ChainDirection.closed.rawValue, /// Skip search if run is closed.
                let nextRunIdx = findTailForHead(point: headPt, direction: ChainDirection(rawValue: headDxn)!)
            {
                joinedRunsIndices.append(nextRunIdx)
                headPt = headPoint(for: nextRunIdx)
                headDxn = srcRuns[nextRunIdx].headTriadTo
            }

            var tailPt = tailPoint(for: runIdx)
            var tailDxn = srcRuns[runIdx].tailTriadFrom
            while
                tailDxn != ChainDirection.closed.rawValue, /// Skip search if run is closed.
                let prevRunIdx = findHeadForTail(point: tailPt, direction: ChainDirection(rawValue: tailDxn)!)
            {
                joinedRunsIndices.insert(prevRunIdx, at: 0)
                tailPt = tailPoint(for: prevRunIdx)
                tailDxn = srcRuns[prevRunIdx].tailTriadFrom
            }

            /// At this point, we have an array of connected runs.
            let newRunTail = Int32(newBaseOffset) + nextPointOffset
            for srcRunIdx in joinedRunsIndices {
                /// First, assign each run its new array position.
                let length = srcRuns[srcRunIdx].oldHead - srcRuns[srcRunIdx].oldTail
                let moveTail = Int32(newBaseOffset) + nextPointOffset
                srcRuns[srcRunIdx].newTail = moveTail
                srcRuns[srcRunIdx].newHead = moveTail + length
                nextPointOffset += length
            }
            let newRunHead = Int32(newBaseOffset) + nextPointOffset
            
            var newTailFrom = srcRuns[joinedRunsIndices.first!].tailTriadFrom
            var newHeadTo = srcRuns[joinedRunsIndices.last!].headTriadTo
            
            _ = {
                let headDxn = ChainDirection(rawValue: headDxn)!
                let tailDxn = ChainDirection(rawValue: tailDxn)!
                
                /// Check if already closed.
                if headDxn == .closed {
                    precondition(tailDxn == .closed)
                    return
                }
                
                /// Check if the new run is closed.
                if headDxn.inverse == tailDxn && headPt[headDxn] == tailPt {
                    precondition(tailPt[tailDxn] == headPt)
                    newTailFrom = ChainDirection.closed.rawValue
                    newHeadTo = ChainDirection.closed.rawValue
                }
            }()
            
            
            /// Finally, add the new run.
            let newRun = Run(
                oldTail: newRunTail, oldHead: newRunHead,
                newTail: -1, newHead: -1,
                tailTriadFrom: newTailFrom, headTriadTo: newHeadTo
            )
            
            #if SHOW_GRID_WORK
            /// Print all the points from all sources
            var __pts: [PixelPoint] = []
            for srcRunIdx in joinedRunsIndices {
                for i in srcRuns[srcRunIdx].oldTail..<srcRuns[srcRunIdx].oldHead {
                    __pts.append(srcPts[Int(i)])
                }
            }
            debugPrint("newRun \(newRun) \(__pts)")
            #endif
            
            dstRuns[Int(newBaseOffset + nextRunOffset)] = newRun
            nextRunOffset += 1
        }

        while aRunIndices.isEmpty == false {
            let aRunIdx = aRunIndices.removeLast()
            #if SHOW_GRID_WORK
            debugPrint("joining run \(srcRuns[aRunIdx]) with head \(headPoint(for: aRunIdx)) and tail \(tailPoint(for: aRunIdx))")
            #endif
            join(runIdx: aRunIdx)
        }
        while bRunIndices.isEmpty == false {
            let bRunIdx = bRunIndices.removeLast()
            #if SHOW_GRID_WORK
            debugPrint("joining run \(srcRuns[bRunIdx]) with head \(headPoint(for: bRunIdx)) and tail \(tailPoint(for: bRunIdx))")
            #endif
            join(runIdx: bRunIdx)
        }

        let blitRequests = a.runIndices(imageSize: imageSize, gridSize: gridSize) + b.runIndices(imageSize: imageSize, gridSize: gridSize)
        
        /// Update remaining region
        a.runsCount = nextRunOffset
        a.size = newRegionSize
        
        return blitRequests
    }
}

func baseOffset(imageSize: PixelSize, gridSize: PixelSize, regionSize: PixelSize, gridPos: GridPosition) -> UInt32 {
    4 * ((imageSize.width * gridSize.height * gridPos.row) + (gridSize.width * regionSize.height * gridPos.col))
}

func baseOffset(grid: Grid, region: Region) -> UInt32 {
    baseOffset(imageSize: grid.imageSize, gridSize: grid.gridSize, regionSize: region.size, gridPos: region.gridPos)
}

#warning("TEMP: CPU BLIT")
/// For each source run, copy its points to the destination.
func cpuBlit(
    runIndices: [Int],
    srcPts: UnsafeMutablePointer<PixelPoint>, srcRuns: UnsafeMutablePointer<Run>,
    dstPts: UnsafeMutablePointer<PixelPoint>
) -> Void {
    for runIdx in runIndices {
        cpuBlit(run: srcRuns[runIdx], srcPts: srcPts, dstPts: dstPts)
    }
}

func cpuBlit(
    run: Run,
    srcPts: UnsafeMutablePointer<PixelPoint>,
    dstPts: UnsafeMutablePointer<PixelPoint>
) -> Void {
    #if SHOW_GRID_WORK
    debugPrint("[BLIT] \(run)")
    #endif
    let length = run.oldHead - run.oldTail
    for i in 0..<length {
        dstPts[Int(run.newTail + i)] = srcPts[Int(run.oldTail + i)]
    }
}
