//
//  Profiler.swift
//  
//
//  Created by Secret Asian Man Dev on 13/2/23.
//

import Foundation

extension Dictionary where Key: Comparable {
    func sortedByKey() -> [(Key, Value)] {
        self.sorted { (arg1, arg2) in
            let (k2, _) = arg2
            let (k1, _) = arg1
            return k1 < k2
        }
    }
}

public protocol CodeRegion: Hashable, CaseIterable { }
enum SuzukiRegion: Hashable, CaseIterable, CodeRegion {
    case blit, trailingCopy, binarize, startChains, overall, makeTexture, initRegions, bufferInit, blitWait, runIndices
    case combineAll, combine, combineFindPartner, combineJoin
    case lutCopy
}

internal let SuzukiProfiler = Profiler<SuzukiRegion>()


public actor Profiler<Region: CodeRegion> {

    private var timing: [Region: (Int, TimeInterval)] = {
        var dict = [Region: (Int, TimeInterval)]()
        for region in Region.allCases {
            dict[region] = (0, 0)
        }
        return dict
    }()
    
    private var iterationTiming: [Int: (Int, TimeInterval)] = {
        var dict = [Int: (Int, TimeInterval)]()
        return dict
    }()

    public init() { }
    
    private func addIsolated(_ duration: TimeInterval, to region: Region) {
        let (count, total) = timing[region]!
        self.timing[region] = (count + 1, total + duration)
    }
    nonisolated func add(_ duration: TimeInterval, to region: Region) {
        #if PROFILE_SUZUKI
        Task(priority: .high) {
            await addIsolated(duration, to: region)
        }
        #endif
    }
    
    private func addIsolated(_ duration: TimeInterval, iteration: Int) -> Void {
        let (count, total) = iterationTiming[iteration] ?? (0, 0)
        self.iterationTiming[iteration] = (count + 1, total + duration)
    }
    nonisolated func add(_ duration: TimeInterval, iteration: Int) -> Void {
        #if PROFILE_SUZUKI
        Task(priority: .high) {
            await addIsolated(duration, iteration: iteration)
        }
        #endif
    }

    nonisolated func time(_ region: Region, _ block: () -> Void) {
        #if PROFILE_SUZUKI
        let start = CFAbsoluteTimeGetCurrent()
        #endif
        
        block()
        
        #if PROFILE_SUZUKI
        let end = CFAbsoluteTimeGetCurrent()
        self.add(end - start, to: region)
        #endif
    }
    
    nonisolated func time(_ iteration: Int, _ block: () -> Void) {
        #if PROFILE_SUZUKI
        let start = CFAbsoluteTimeGetCurrent()
        #endif
        
        block()
        
        #if PROFILE_SUZUKI
        let end = CFAbsoluteTimeGetCurrent()
        self.add(end - start, iteration: iteration)
        #endif
    }
    
    nonisolated func time<Result>(_ region: Region, _ block: () -> Result) -> Result {
        #if PROFILE_SUZUKI
        let start = CFAbsoluteTimeGetCurrent()
        #endif
        
        let result = block()
        
        #if PROFILE_SUZUKI
        let end = CFAbsoluteTimeGetCurrent()
        self.add(end - start, to: region)
        #endif

        return result
    }

    public func report() async {
        #if PROFILE_SUZUKI
        /// Wait for everything to finish.
        try! await Task.sleep(nanoseconds: UInt64(1_000_000_000 * 2))
        
        let dict = await self.timing
//        for (region, results) in dict where [.overall, .combineAll, .combine].contains(region) {
            for (region, results) in dict where results.0 > 0 {
            let (count, time) = results
            print("\(region): \(time)s, \(count) (avg \(time / Double(count))s)")
        }
        
        let timingDict = await self.iterationTiming
        for (iteration, results) in timingDict.sortedByKey() {
            let (count, time) = results
            print("\(iteration): \(time)s, \(count) (avg \(time / Double(count))s)")
        }
        #endif
    }
}

internal func printTime<Result>(_ block: () -> Result) -> Result {
    let start = CFAbsoluteTimeGetCurrent()
    let result = block()
    let end = CFAbsoluteTimeGetCurrent()
    debugPrint(String(format: "Time: %.2f s", end - start))
    return result
}
