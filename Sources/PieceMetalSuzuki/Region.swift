import Foundation

struct PixelSize: Equatable, CustomStringConvertible {
    let width: UInt32
    let height: UInt32

    var description: String {
        return "w\(width)h\(height)"
    }
}

/// A CPU only struct used to organize Runs.
/// Class allows easy in-place manipulation.
class Region { 
    let origin: PixelPoint
    
    /// Spatial size of the grid, which may be smaller at the trailing and bottom edges.
    var size: PixelSize
    
    var gridRow: UInt32
    var gridCol: UInt32

    /// Number of elements in the region.
    var runsCount: UInt32

    init(origin: PixelPoint, size: PixelSize, gridRow: UInt32, gridCol: UInt32, runsCount: UInt32) {
        self.origin = origin
        self.size = size
        self.gridRow = gridRow
        self.gridCol = gridCol
        self.runsCount = runsCount
    }

    /// Get the base offset of the region in the image buffer.
//    func base(imgSize: PixelSize, regionSize: PixelSize) -> UInt32 {
//        let pixelAddr = (imgSize.width * regionSize.height * gridRow) + (regionSize.width * regionSize.height * gridCol)
//        return pixelAddr * 4
//    }
}

extension Region: CustomStringConvertible {
    var description: String {
        return "Region(origin: \(origin), gridRow: \(gridRow), gridCol: \(gridCol), \(runsCount) runs)"
    }
}

struct Grid {
    let imageSize: PixelSize
    var regionSize: PixelSize
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
        pointsVertical: UnsafeMutablePointer<PixelPoint>,
        runsVertical: UnsafeMutablePointer<Run>,
        pointsHorizontal: UnsafeMutablePointer<PixelPoint>,
        runsHorizontal: UnsafeMutablePointer<Run>
    ) -> Void {
        var dxn = ReduceDirection.vertical
        while (regions.count > 1) || (regions[0].count > 1) {
            
            let numRows = regions.count
            let numCols = regions[0].count
            
            switch dxn {
            case .horizontal:
                let newRegionSize = PixelSize(width: regionSize.width * 2, height: regionSize.height)
                for rowIdx in 0..<numRows {
                    for colIdx in stride(from: 0, to: numCols - 1, by: 2).reversed() {
                        let a = regions[rowIdx][colIdx]
                        let b = regions[rowIdx].remove(at: colIdx + 1)
                        combine(a: a, b: b, dxn: dxn,
                                srcPts: pointsVertical, srcRuns: runsVertical,
                                dstPts: pointsHorizontal, dstRuns: runsHorizontal)
                    }
                }
                regionSize = newRegionSize
                
                #if SHOW_GRID_WORK
                for reg in regions.joined() {
                    dump(region: reg, points: pointsHorizontal, runs: runsHorizontal)
                }
                #endif
            
            case .vertical:
                let newRegionSize = PixelSize(width: regionSize.width, height: regionSize.height * 2)
                for rowIdx in stride(from: 0, to: numRows - 1, by: 2).reversed() {
                    for colIdx in 0..<numCols {
                        let a = regions[rowIdx][colIdx]
                        let b = regions[rowIdx+1][colIdx]
                        combine(a: a, b: b, dxn: dxn,
                                srcPts: pointsHorizontal, srcRuns: runsHorizontal,
                                dstPts: pointsVertical, dstRuns: runsVertical)
                    }
                    /// Remove entire row at once.
                    regions.remove(at: rowIdx + 1)
                }
                regionSize = newRegionSize
                
                #if SHOW_GRID_WORK
                for reg in regions.joined() {
                    dump(region: reg, points: pointsVertical, runs: runsVertical)
                }
                #endif
            }
            dxn.flip()
        }
    }
    
    #if SHOW_GRID_WORK
    func dump(region: Region, points: UnsafeMutablePointer<PixelPoint>, runs: UnsafeMutablePointer<Run>) {
        let baseOffset = 4 * ((imageSize.width * regionSize.height * region.gridRow) + (regionSize.width * regionSize.height * region.gridCol))
        debugPrint("[DUMP]: \(region)")
        for offset in 0..<Int(region.runsCount) {
            let runBufferOffset = Int(offset + Int(baseOffset))
            let run = runs[runBufferOffset]
            let chain = (run.oldTail..<run.oldHead).map { points[Int($0)] }
            debugPrint("- \(run) \(chain) @\(runBufferOffset)(\(baseOffset)+\(offset))")
        }
    }
    #endif
    
    func combine(
        a: Region, b: Region, dxn: ReduceDirection,
        srcPts: UnsafeMutablePointer<PixelPoint>, srcRuns: UnsafeMutablePointer<Run>,
        dstPts: UnsafeMutablePointer<PixelPoint>, dstRuns: UnsafeMutablePointer<Run>
    ) -> Void {
        #if SHOW_GRID_WORK
        debugPrint("Combining \(a) and \(b)")
        debugPrint("imgSize: \(imageSize), regionSize: \(regionSize)")
        #endif
        let aBaseOffset: UInt32 = 4 * ((imageSize.width * regionSize.height * a.gridRow) + (regionSize.width * regionSize.height * a.gridCol))
        let bBaseOffset: UInt32 = 4 * ((imageSize.width * regionSize.height * b.gridRow) + (regionSize.width * regionSize.height * b.gridCol))
        let newBaseOffset: UInt32
        switch dxn {
        case .vertical:
            newBaseOffset = 4 * ((imageSize.width * (regionSize.height * 2) * (a.gridRow / 2)) +  (regionSize.width      * (regionSize.height * 2) * a.gridCol      ))
        case .horizontal:
            newBaseOffset = 4 * ((imageSize.width *  regionSize.height      *  a.gridRow     ) + ((regionSize.width * 2) *  regionSize.height      * (a.gridCol / 2)))
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
            
            /// Finally, add the new run.
            let newRun = Run(
                oldTail: newRunTail, oldHead: newRunHead,
                newTail: -1, newHead: -1,
                tailTriadFrom: srcRuns[joinedRunsIndices.first!].tailTriadFrom,
                headTriadTo:   srcRuns[joinedRunsIndices.last!].headTriadTo
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

        #warning("TEMP: CPU BLIT")
        /// For each source run, copy its points to the destination.
        for aRunIdx in 0..<a.runsCount {
            let srcRun = srcRuns[Int(aBaseOffset) + Int(aRunIdx)]
            let length = srcRun.oldHead - srcRun.oldTail
            for i in 0..<length {
                dstPts[Int(srcRun.newTail + i)] = srcPts[Int(srcRun.oldTail + i)]
            }
        }
        for bRunIdx in 0..<b.runsCount {
            let srcRun = srcRuns[Int(bBaseOffset) + Int(bRunIdx)]
            let length = srcRun.oldHead - srcRun.oldTail
            for i in 0..<length {
                dstPts[Int(srcRun.newTail + i)] = srcPts[Int(srcRun.oldTail + i)]
            }
        }
        
        /// Update remaining region
        switch dxn {
        case .horizontal:
            a.gridCol /= 2
        case .vertical:
            a.gridRow /= 2
        }
        a.runsCount = nextRunOffset
    }
}



