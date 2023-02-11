import Foundation

struct PixelSize: Equatable, CustomStringConvertible {
    let width: UInt32
    let height: UInt32

    var description: String {
        return "w\(width)h\(height)"
    }
}

/// A CPU only struct used to organize Runs.
class Region { 
    let origin: PixelPoint
    var gridRow: UInt32
    var gridCol: UInt32

    // Number of elements in the region.
    let runsCount: UInt32

    init(origin: PixelPoint, gridRow: UInt32, gridCol: UInt32, runsCount: UInt32) {
        self.origin = origin
        self.gridRow = gridRow
        self.gridCol = gridCol
        self.runsCount = runsCount
    }

    /// Get the base offset of the region in the image buffer.
    func base(imgSize: PixelSize, regionSize: PixelSize) -> UInt32 {
        let pixelAddr = (imgSize.width * regionSize.height * gridRow) + (regionSize.width * regionSize.height * gridCol)
        return pixelAddr * 4
    }
}

extension Region: CustomStringConvertible {
    var description: String {
        return "Region(origin: \(origin), gridRow: \(gridRow), gridCol: \(gridCol), \(runsCount) runs)"
    }
}

enum Source { case A, B }
func combine(
    a: Region, b: Region,
    srcPts: UnsafeMutablePointer<PixelPoint>, srcRuns: UnsafeMutablePointer<Run>, 
    dstPts: UnsafeMutablePointer<PixelPoint>, dstRuns: UnsafeMutablePointer<Run>,
    imgSize: PixelSize, regionSize: PixelSize
) -> Void {
    let aBaseOffset = a.base(imgSize: imgSize, regionSize: regionSize)
    let bBaseOffset = b.base(imgSize: imgSize, regionSize: regionSize)

    var aRunIndices = (0..<Int(a.runsCount)).map { $0 + Int(aBaseOffset) }
    var bRunIndices = (0..<Int(b.runsCount)).map { $0 + Int(bBaseOffset) }

    var nextPointOffset = Int32.zero
    var nextRunOffset = 0
    
    func headPoint(for runIdx: Int) -> PixelPoint {
        srcPts[Int(srcRuns[runIdx].oldHead)]
    }
    func tailPoint(for runIdx: Int) -> PixelPoint {
        srcPts[Int(srcRuns[runIdx].oldTail)]
    }

    // Find run, if any, whose tail matches the head at this point, pointing in this direction.
    func findTailForHead(point: PixelPoint, direction: ChainDirection) -> (Int, Source)? {
        precondition(direction != .closed)

        /// For the given head pointer, describe the corresponding tail pointer.
        let tail: PixelPoint = point[direction]
        let from = direction.inverse.rawValue
        func tailDoesMatch(idx: Int) -> Bool {
            return tail == tailPoint(for: idx) && srcRuns[idx].tailTriadFrom == from
        }
        if let aIdx = aRunIndices.firstIndex(where: tailDoesMatch) {
            return (aIdx, .A)
        }
        if let bIdx = bRunIndices.firstIndex(where: tailDoesMatch) {
            return (bIdx, .B)
        }
        return nil
    }

    func findHeadForTail(point: PixelPoint, direction: ChainDirection) -> (Int, Source)? {
        precondition(direction != .closed)

        /// For the given tail pointer, describe the corresponding head pointer.
        let head: PixelPoint = point[direction]
        let to = direction.inverse.rawValue
        func headDoesMatch(idx: Int) -> Bool {
            return head == headPoint(for: idx) && srcRuns[idx].headTriadTo == to
        }

        if let aIdx = aRunIndices.firstIndex(where: headDoesMatch) {
            return (aIdx, .A)
        }
        if let bIdx = bRunIndices.firstIndex(where: headDoesMatch) {
            return (bIdx, .B)
        }
        return nil
    }

    func join(runIdx: Int, source: Source) -> Void {
        var joinedRunsIndices: [(Int, Source)] = [(runIdx, source)]

        var headPt = headPoint(for: runIdx)
        var headDxn = srcRuns[runIdx].headTriadTo
        while
            headDxn != ChainDirection.closed.rawValue, /// Skip search if run is closed.
            let (nextRunIdx, src) = findTailForHead(point: headPt, direction: ChainDirection(rawValue: headDxn)!)
        {
            joinedRunsIndices.append((nextRunIdx, src))
            headPt = headPoint(for: nextRunIdx)
            headDxn = srcRuns[nextRunIdx].headTriadTo
        }

        var tailPt = tailPoint(for: runIdx)
        var tailDxn = srcRuns[runIdx].tailTriadFrom
        while
            tailDxn != ChainDirection.closed.rawValue, /// Skip search if run is closed.
            let (prevRunIdx, src) = findHeadForTail(point: tailPt, direction: ChainDirection(rawValue: tailDxn)!)
        {
            joinedRunsIndices.insert((prevRunIdx, src), at: 0)
            tailPt = tailPoint(for: prevRunIdx)
            tailDxn = srcRuns[prevRunIdx].tailTriadFrom
        }

        /// At this point, we have an array of connected runs.
        for (srcRunIdx, src) in joinedRunsIndices {
            /// First, assign each run its new array position.
            let length = srcRuns[srcRunIdx].oldTail - srcRuns[srcRunIdx].oldHead
            let newHead = Int32(aBaseOffset) + nextPointOffset
            srcRuns[srcRunIdx].newHead = newHead
            srcRuns[srcRunIdx].newTail = newHead + length
            nextPointOffset += length
        }

        /// Finally, add the new run.
        dstRuns[Int(aBaseOffset) + nextRunOffset] = Run(
            oldHead: srcRuns[joinedRunsIndices.last!.0].oldHead,
            oldTail: srcRuns[joinedRunsIndices.first!.0].oldTail,
            newHead: srcRuns[joinedRunsIndices.last!.0].oldHead,  /// This value is not used.
            newTail: srcRuns[joinedRunsIndices.first!.0].oldTail, /// This value is not used.
            tailTriadFrom: srcRuns[joinedRunsIndices.first!.0].tailTriadFrom,
            headTriadTo:   srcRuns[joinedRunsIndices.last!.0].headTriadTo
        )
        nextRunOffset += 1
    }

    while aRunIndices.isEmpty == false {
        join(runIdx: aRunIndices.removeLast(), source: .A)
    }
    while bRunIndices.isEmpty == false {
        join(runIdx: bRunIndices.removeLast(), source: .B)
    }

    /// Create updated region.
    #warning("TODO: fix region size")
    Region(
        origin: a.origin,
        gridRow: a.gridRow, gridCol: a.gridCol,
        runsCount: UInt32(nextRunOffset)
    )
}
