import Foundation
import Metal

struct Grid {
    let imageSize: PixelSize
    
    /// Assumed region size. Actual region size is smaller at the bottom and trailing edges.
    var gridSize: PixelSize
    
    var regions: [[Region]]
    
    let patternSize: PatternSize
    
    init(imageSize: PixelSize, regions: [[Region]], patternSize: PatternSize) {
        self.imageSize = imageSize
        self.regions = regions
        self.patternSize = patternSize
        self.gridSize = patternSize.coreSize
    }
    
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
        pointsFilled: Buffer<PixelPoint>,
        runsFilled: Buffer<Run>,
        pointsUnfilled: Buffer<PixelPoint>,
        runsUnfilled: Buffer<Run>,
        commandQueue: MTLCommandQueue
    ) -> Void {
        var dxn = ReduceDirection.vertical
        let pointsHorizontal = pointsFilled
        let runsHorizontal = runsFilled
        let pointsVertical = pointsUnfilled
        let runsVertical = runsUnfilled
        
        var srcPts: UnsafeMutablePointer<PixelPoint>
        var dstPts: UnsafeMutablePointer<PixelPoint>
        var srcRuns: UnsafeMutablePointer<Run>
        var dstRuns: UnsafeMutablePointer<Run>
        
        var iteration = 0
        while (regions.count > 1) || (regions[0].count > 1) {
            let start = CFAbsoluteTimeGetCurrent()
            
            let numRows = regions.count
            let numCols = regions[0].count
            
            switch dxn {
            case .horizontal:
                (srcRuns, dstRuns) = (runsVertical.array, runsHorizontal.array)
                (srcPts, dstPts) = (pointsVertical.array, pointsHorizontal.array)

                if numCols.isMultiple(of: 2) == false {
                    Profiler.time(.trailingCopy) {
                        /// Request last column blit.
                        for row in regions {
                            let region = row.last!
                            for runIdx in region.runIndices(imageSize: imageSize, gridSize: gridSize) {
                                dstRuns[runIdx] = srcRuns[runIdx]
                                srcRuns[runIdx].newTail = srcRuns[runIdx].oldTail
                                srcRuns[runIdx].newHead = srcRuns[runIdx].oldHead
                            }
                            
                            let runIndices = Array(region.runIndices(imageSize: imageSize, gridSize: gridSize))
                            Profiler.time(.blit) {
                                cpuBlit(runIndices: runIndices, srcPts: srcPts, srcRuns: srcRuns, dstPts: dstPts)
                            }
                        }
                    }
                }
                
                let newGridSize = PixelSize(width: gridSize.width * 2, height: gridSize.height)
                Profiler.time(.combine) {
                    var indices: [(Int, Int)] = []
                    for col in stride(from: 0, to: numCols - 1, by: 2).reversed() {
                        for row in 0..<numRows {
                            indices.append((row, col))
                        }
                    }
                    DispatchQueue.concurrentPerform(iterations: indices.count) { indicesIdx in
                        let (row, col) = indices[indicesIdx]
                        let a = regions[row][col]
                        let b = regions[row][col + 1]
                        let newRequests = combine(a: a, b: b,
                                dxn: dxn, newGridSize: newGridSize,
                                srcPts: srcPts, srcRuns: srcRuns,
                                dstRuns: dstRuns)
                        cpuBlit(runIndices: newRequests, srcPts: srcPts, srcRuns: srcRuns, dstPts: dstPts)
                        /// Update grid position for remaining regions.
                    }

                    DispatchQueue.concurrentPerform(iterations: numRows) { rowIdx in
                        for region in regions[rowIdx] {
                            region.gridPos.col /= 2
                        }
                    }
                    
                    for rowIdx in 0..<numRows {
                        for colIdx in stride(from: 0, to: numCols - 1, by: 2).reversed() {
                            regions[rowIdx].remove(at: colIdx + 1)
                        }
                    }
                }
                gridSize = newGridSize
            
            case .vertical:
                (srcRuns, dstRuns) = (runsHorizontal.array, runsVertical.array)
                (srcPts, dstPts) = (pointsHorizontal.array, pointsVertical.array)

                if numRows.isMultiple(of: 2) == false {
                    Profiler.time(.trailingCopy) {
                        /// Request last column blit.
                        for region in regions.last! {
                            for runIdx in region.runIndices(imageSize: imageSize, gridSize: gridSize) {
                                dstRuns[runIdx] = srcRuns[runIdx]
                                srcRuns[runIdx].newTail = srcRuns[runIdx].oldTail
                                srcRuns[runIdx].newHead = srcRuns[runIdx].oldHead
                            }
                            
                            let runIndices = Array(region.runIndices(imageSize: imageSize, gridSize: gridSize))
                            Profiler.time(.blit) {
                                cpuBlit(runIndices: runIndices, srcPts: srcPts, srcRuns: srcRuns, dstPts: dstPts)
                            }
                        }
                    }
                }
                
                let newGridSize = PixelSize(width: gridSize.width, height: gridSize.height * 2)
                Profiler.time(.combine) {
                    var indices: [(Int, Int)] = []
                    for col in 0..<numCols {
                        for row in stride(from: 0, to: numRows - 1, by: 2).reversed() {
                            indices.append((row, col))
                        }
                    }
                    DispatchQueue.concurrentPerform(iterations: indices.count) { indicesIdx in
                        let (row, col) = indices[indicesIdx]
                        let a = regions[row][col]
                        let b = regions[row+1][col]
                        let newRequests = combine(a: a, b: b,
                                dxn: dxn, newGridSize: newGridSize,
                                srcPts: srcPts, srcRuns: srcRuns,
                                dstRuns: dstRuns)
                        cpuBlit(runIndices: newRequests, srcPts: srcPts, srcRuns: srcRuns, dstPts: dstPts)
                    }
                    for rowIdx in stride(from: 0, to: numRows - 1, by: 2).reversed() {
                        /// Remove entire row at once.
                        regions.remove(at: rowIdx + 1)
                    }
                }
                /// Update grid position for remaining regions.
                for rowIdx in 0..<regions.count {
                    for colIdx in 0..<numCols {
                        regions[rowIdx][colIdx].gridPos.row /= 2
                    }
                }
                gridSize = newGridSize
            }
                
            #if SHOW_GRID_WORK
            for reg in regions.joined() {
                dump(region: reg, points: dstPts, runs: dstRuns)
            }
            #endif
            
            dxn.flip()
            
            let end = CFAbsoluteTimeGetCurrent()
            if iteration == 0 {
                debugPrint("Iter 0: \(end - start)")
            }
            Profiler.add(end - start, iteration: iteration)
            iteration += 1
        }
        
        /// Return final results.
        let pointBuffer: UnsafeMutablePointer<PixelPoint>
        let runBuffer: UnsafeMutablePointer<Run>
        
        switch dxn {
        case .horizontal: /// Last iteration was vertical.
            pointBuffer = pointsVertical.array
            runBuffer = runsVertical.array
        case .vertical: /// Last iteration was horizontal.
            pointBuffer = pointsHorizontal.array
            runBuffer = runsHorizontal.array
        }
        
        #if DEBUG
        for runIdx in regions[0][0].runIndices(imageSize: imageSize, gridSize: gridSize) {
            let run = runBuffer[runIdx]
//            print((run.oldTail..<run.oldHead).map { pointBuffer[Int($0)] })
            assert(run.isValid)
            assert(run.headTriadTo == ChainDirection.closed.rawValue)
            assert(run.tailTriadFrom == ChainDirection.closed.rawValue)
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
    
    /**
     Recall that
     - `a` and `b` represent regions on a grid, whose positions can be translated into memory offsets.
     - a series of `Run`s live at those offsets. In turn, each `Run` points to a range of `Points`.
     
     The algorithm's objective is to join `Run`s into longer `Run`s by finding pairs with one's head matching the other's tail.
     Both the location and direction must match.
     Matching means having a pixel in the correct direction relative to the other pixel.
     e.g. if fragment Alice has head position (3,5) pointed right, then fragment Bob with tail at (3,6) pointed left is a match.
     
     The algorithm proceeds as follows:
     - we have a pool of runs from regions `a` and `b`.
     - examine each run in turn, until there are none.
        - search the pool for a run with tail matching this run's head.
        - if found, keep going until no matching run is found.
        - likewise for the original run's tail, join matching heads until there are none.
        - runs found in this way are removed from the pool.
        - take this "line" of runs and assign it a contiguous location in the desination buffer.
        - tell each run in the line where it should copy to in the destination.
        - create a joined run representing the entire line.
     
     That's it!
     */
    func combine(
        a: Region, b: Region,
        dxn: ReduceDirection, newGridSize: PixelSize,
        srcPts: UnsafeMutablePointer<PixelPoint>, srcRuns: UnsafeMutablePointer<Run>,
        dstRuns: UnsafeMutablePointer<Run>
    ) -> [Int] {
        var combiner = Combiner(a: a, b: b, dxn: dxn, newGridSize: newGridSize, srcPts: srcPts, srcRuns: srcRuns, dstRuns: dstRuns, grid: self)
        combiner.work()

        let blitRequests = Array(a.runIndices(imageSize: imageSize, gridSize: gridSize)) + Array(b.runIndices(imageSize: imageSize, gridSize: gridSize))
        
        /// Update remaining region
        a.runsCount = combiner.nextRunOffset
        a.size = combiner.newRegionSize
        
        return blitRequests
    }
    
    struct Combiner {
        
        let newBaseOffset: UInt32
        let newRegionSize: PixelSize
        
        var runIndices: [Int]
        
        var nextPointOffset = Int32.zero
        var nextRunOffset = UInt32.zero
        
        let srcPts: UnsafeMutablePointer<PixelPoint>
        let srcRuns: UnsafeMutablePointer<Run>
        let dstRuns: UnsafeMutablePointer<Run>
        
        let pointsPerPixel: UInt32
        
        init(
            a: Region, b: Region,
            dxn: ReduceDirection, newGridSize: PixelSize,
            srcPts: UnsafeMutablePointer<PixelPoint>, srcRuns: UnsafeMutablePointer<Run>,
            dstRuns: UnsafeMutablePointer<Run>,
            grid: Grid
        ) {
            self.srcPts = srcPts
            self.srcRuns = srcRuns
            self.dstRuns = dstRuns
            self.pointsPerPixel = grid.patternSize.pointsPerPixel
            
            #if SHOW_GRID_WORK
            debugPrint("Combining \(a) and \(b)")
            #endif
            let aBaseOffset = baseOffset(grid: grid, region: a)
            let bBaseOffset = baseOffset(grid: grid, region: b)
            self.runIndices = (0..<Int(a.runsCount)).map { $0 + Int(aBaseOffset) }
                            + (0..<Int(b.runsCount)).map { $0 + Int(bBaseOffset) }
            
            switch dxn {
            case .vertical:
                let bottomEdge = ((a.gridPos.row / 2) + 1) * newGridSize.height
                let newRegionHeight = bottomEdge > grid.imageSize.height
                    ? grid.imageSize.height - (a.gridPos.row / 2) * newGridSize.height
                    : newGridSize.height
                self.newRegionSize = PixelSize(
                    width: a.size.width,
                    height: newRegionHeight
                )
            case .horizontal:
                let rightEdge = ((a.gridPos.col / 2) + 1) * newGridSize.width
                let newRegionWidth = rightEdge > grid.imageSize.width
                    ? grid.imageSize.width - (a.gridPos.col / 2) * newGridSize.width
                    : newGridSize.width
                self.newRegionSize = PixelSize(
                    width: newRegionWidth,
                    height: a.size.height
                )
            }

            switch dxn {
            case .vertical:
                self.newBaseOffset = baseOffset(imageSize: grid.imageSize, gridSize: newGridSize, regionSize: newRegionSize, gridPos: GridPosition(row: a.gridPos.row / 2, col: a.gridPos.col), patternSize: grid.patternSize)
            case .horizontal:
                self.newBaseOffset = baseOffset(imageSize: grid.imageSize, gridSize: newGridSize, regionSize: newRegionSize, gridPos: GridPosition(row: a.gridPos.row, col: a.gridPos.col / 2), patternSize: grid.patternSize)
            }
        }
        
        private func headPoint(for runIdx: Int) -> PixelPoint {
            srcPts[Int(srcRuns[runIdx].oldHead - 1)]
        }
        
        private func tailPoint(for runIdx: Int) -> PixelPoint {
            srcPts[Int(srcRuns[runIdx].oldTail)]
        }
        
        /// Find run, if any, whose tail matches the head at this point, pointing in this direction.
        private mutating func findTailForHead(point: PixelPoint, direction: ChainDirection) -> Int? {
            precondition(direction != .closed)

            /// For the given head pointer, describe the corresponding tail pointer.
            let tail: PixelPoint = point[direction]
            let from = direction.inverse.rawValue
            func tailDoesMatch(idx: Int) -> Bool {
                return tail == tailPoint(for: idx) && srcRuns[idx].tailTriadFrom == from
            }
            if let runIdxIdx = runIndices.firstIndex(where: tailDoesMatch) {
                let runIdx = runIndices.remove(at: runIdxIdx)
                return runIdx
            }
            return nil
        }

        private mutating func findHeadForTail(point: PixelPoint, direction: ChainDirection) -> Int? {
            precondition(direction != .closed)

            /// For the given tail pointer, describe the corresponding head pointer.
            let head: PixelPoint = point[direction]
            let to = direction.inverse.rawValue
            func headDoesMatch(idx: Int) -> Bool {
                return head == headPoint(for: idx) && srcRuns[idx].headTriadTo == to
            }
            if let runIdxIdx = runIndices.firstIndex(where: headDoesMatch) {
                let runIdx = runIndices.remove(at: runIdxIdx)
                return runIdx
            }
            return nil
        }

        private mutating func join(runIdx: Int) -> Void {
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
        
        mutating func work() -> Void {
            while runIndices.isEmpty == false {
                let runIdx = runIndices.removeLast()
                #if SHOW_GRID_WORK
                debugPrint("joining run @\(runIdx) \(srcRuns[runIdx]) with head \(headPoint(for: runIdx)) and tail \(tailPoint(for: runIdx))")
                #endif
                join(runIdx: runIdx)
            }
        }
    }
}

func baseOffset(imageSize: PixelSize, gridSize: PixelSize, regionSize: PixelSize, gridPos: GridPosition, patternSize: PatternSize) -> UInt32 {
    let rowOffset = imageSize.width.roundedUp(toClosest: patternSize.coreSize.width) * gridSize.height * gridPos.row
    let colOffset = gridSize.width * regionSize.height * gridPos.col
    return patternSize.pointsPerPixel * (rowOffset + colOffset)
}

func baseOffset(grid: Grid, region: Region) -> UInt32 {
    baseOffset(imageSize: grid.imageSize, gridSize: grid.gridSize, regionSize: region.size, gridPos: region.gridPos, patternSize: grid.patternSize)
}

extension Grid {
    mutating func combineAllForLUT(
        coreSize: PixelSize,
        device: MTLDevice,
        pointsFilled: Buffer<PixelPoint>,
        runsFilled: Buffer<Run>,
        pointsUnfilled: Buffer<PixelPoint>,
        runsUnfilled: Buffer<Run>,
        commandQueue: MTLCommandQueue
    ) -> (Region, [Run], [PixelPoint]) {
        /// First iteration will combine regions with their horizontal neighbors.
        /// Hence we copy from the "vertical" buffers to the "horizontal" buffers.
        var dxn = ReduceDirection.horizontal
        let pointsVertical = pointsFilled
        let runsVertical = runsFilled
        let pointsHorizontal = pointsUnfilled
        let runsHorizontal = runsUnfilled
        
        var srcPts: UnsafeMutablePointer<PixelPoint>
        var dstPts: UnsafeMutablePointer<PixelPoint>
        var srcRuns: UnsafeMutablePointer<Run>
        var dstRuns: UnsafeMutablePointer<Run>
        
        while (gridSize != coreSize) {
            
            let numRows = regions.count
            let numCols = regions[0].count
            
            switch dxn {
            case .horizontal:
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
                        
                        let runIndices = Array(region.runIndices(imageSize: imageSize, gridSize: gridSize))
                        cpuBlit(runIndices: runIndices, srcPts: srcPts, srcRuns: srcRuns, dstPts: dstPts)
                    }
                }
                
                let newGridSize = PixelSize(width: gridSize.width * 2, height: gridSize.height)
                var indices: [(Int, Int)] = []
                for col in stride(from: 0, to: numCols - 1, by: 2).reversed() {
                    for row in 0..<numRows {
                        indices.append((row, col))
                    }
                }
                DispatchQueue.concurrentPerform(iterations: indices.count) { indicesIdx in
                    let (row, col) = indices[indicesIdx]
                    let a = regions[row][col]
                    let b = regions[row][col + 1]
                    let newRequests = combine(a: a, b: b,
                            dxn: dxn, newGridSize: newGridSize,
                            srcPts: srcPts, srcRuns: srcRuns,
                            dstRuns: dstRuns)
                    cpuBlit(runIndices: newRequests, srcPts: srcPts, srcRuns: srcRuns, dstPts: dstPts)
                    /// Update grid position for remaining regions.
                }

                DispatchQueue.concurrentPerform(iterations: numRows) { rowIdx in
                    for region in regions[rowIdx] {
                        region.gridPos.col /= 2
                    }
                }
                
                for rowIdx in 0..<numRows {
                    for colIdx in stride(from: 0, to: numCols - 1, by: 2).reversed() {
                        regions[rowIdx].remove(at: colIdx + 1)
                    }
                }
                gridSize = newGridSize
            
            case .vertical:
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
                        
                        let runIndices = Array(region.runIndices(imageSize: imageSize, gridSize: gridSize))
                        cpuBlit(runIndices: runIndices, srcPts: srcPts, srcRuns: srcRuns, dstPts: dstPts)
                    }
                }
                
                let newGridSize = PixelSize(width: gridSize.width, height: gridSize.height * 2)
                var indices: [(Int, Int)] = []
                for col in 0..<numCols {
                    for row in stride(from: 0, to: numRows - 1, by: 2).reversed() {
                        indices.append((row, col))
                    }
                }
                DispatchQueue.concurrentPerform(iterations: indices.count) { indicesIdx in
                    let (row, col) = indices[indicesIdx]
                    let a = regions[row][col]
                    let b = regions[row+1][col]
                    let newRequests = combine(a: a, b: b,
                            dxn: dxn, newGridSize: newGridSize,
                            srcPts: srcPts, srcRuns: srcRuns,
                            dstRuns: dstRuns)
                    cpuBlit(runIndices: newRequests, srcPts: srcPts, srcRuns: srcRuns, dstPts: dstPts)
                }
                for rowIdx in stride(from: 0, to: numRows - 1, by: 2).reversed() {
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
        case .horizontal: /// Last iteration was vertical.
            pointBuffer = pointsVertical.array
            runBuffer = runsVertical.array
        case .vertical: /// Last iteration was horizontal.
            pointBuffer = pointsHorizontal.array
            runBuffer = runsHorizontal.array
        }
        
        #if DEBUG
        for runIdx in regions[0][0].runIndices(imageSize: imageSize, gridSize: gridSize) {
            let run = runBuffer[runIdx]
//            print((run.oldTail..<run.oldHead).map { pointBuffer[Int($0)] })
            assert(run.isValid)
        }
        #endif
        
        let center = regions[1][1]
        var runs: [Run] = []
        var points: [PixelPoint] = []
        for runIdx in center.runIndices(imageSize: imageSize, gridSize: gridSize) {
            let run = runBuffer[runIdx]
            runs.append(run)
            points.append(contentsOf: (run.oldTail..<run.oldHead).map { pointBuffer[Int($0)] })
        }
        
        return (center, runs, points)
    }
}
