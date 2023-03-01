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

#if PROFILE_SUZUKI
internal let SuzukiProfiler = Profiler<SuzukiRegion>(enabled: true)
#else
internal let SuzukiProfiler = Profiler<SuzukiRegion>(enabled: false)
#endif

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

    private let ENABLED: Bool
    public init(enabled: Bool) {
        self.ENABLED = enabled
    }
    
    private func addIsolated(_ duration: TimeInterval, to region: Region) {
        let (count, total) = timing[region]!
        self.timing[region] = (count + 1, total + duration)
    }
    nonisolated func add(_ duration: TimeInterval, to region: Region) {
        guard ENABLED else { return }
        Task(priority: .high) {
            await addIsolated(duration, to: region)
        }
    }
    
    private func addIsolated(_ duration: TimeInterval, iteration: Int) -> Void {
        let (count, total) = iterationTiming[iteration] ?? (0, 0)
        self.iterationTiming[iteration] = (count + 1, total + duration)
    }
    nonisolated func add(_ duration: TimeInterval, iteration: Int) -> Void {
        guard ENABLED else { return }
        Task(priority: .high) {
            await addIsolated(duration, iteration: iteration)
        }
    }

    nonisolated func time(_ region: Region, _ block: () -> Void) {
        let start = CFAbsoluteTimeGetCurrent()
        
        block()
        
        let end = CFAbsoluteTimeGetCurrent()
        let duration = end - start
        if ENABLED {
            self.add(duration, to: region)
        }
    }
    
    nonisolated func time(_ iteration: Int, _ block: () -> Void) {
        let start = CFAbsoluteTimeGetCurrent()
        
        block()
        
        let end = CFAbsoluteTimeGetCurrent()
        let duration = end - start
        if ENABLED {
            self.add(duration, iteration: iteration)
        }
    }
        
    
    nonisolated func time<Result>(_ region: Region, _ block: () -> Result) -> Result {
        let start = CFAbsoluteTimeGetCurrent()
        
        let result = block()
        
        let end = CFAbsoluteTimeGetCurrent()
        let duration = end - start
        if ENABLED {
            self.add(duration, to: region)
        }
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
