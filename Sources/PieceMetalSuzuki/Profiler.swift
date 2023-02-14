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

public actor Profiler {
    enum CodeRegion: CaseIterable {
        case blit, trailingCopy, binarize, startChains, overall, makeTexture, initRegions, bufferInit, blitWait, runIndices
        case combineAll, combine, combineFindPartner, combineJoin
    }

    private var timing: [CodeRegion: (Int, TimeInterval)] = {
        var dict = [CodeRegion: (Int, TimeInterval)]()
        for region in CodeRegion.allCases {
            dict[region] = (0, 0)
        }
        return dict
    }()
    
    private var iterationTiming: [Int: (Int, TimeInterval)] = {
        var dict = [Int: (Int, TimeInterval)]()
        return dict
    }()

    private init() { }
    public static let shared = Profiler()

    private func add(_ duration: TimeInterval, to region: CodeRegion) -> Void {
        let (count, total) = timing[region]!
        timing[region] = (count + 1, total + duration)
    }
    static func add(_ duration: TimeInterval, to region: CodeRegion) {
        #if PROFILER_ON
        Task(priority: .high) {
            await Profiler.shared.add(duration, to: region)
        }
        #endif
    }
    
    private func add(_ duration: TimeInterval, iteration: Int) -> Void {
        let (count, total) = iterationTiming[iteration] ?? (0, 0)
        iterationTiming[iteration] = (count + 1, total + duration)
    }
    static func add(_ duration: TimeInterval, iteration: Int) -> Void {
        #if PROFILER_ON
        Task(priority: .high) {
            await Profiler.shared.add(duration, iteration: iteration)
        }
        #endif
    }

    static func time(_ region: CodeRegion, _ block: () -> Void) {
        #if PROFILER_ON
        let start = CFAbsoluteTimeGetCurrent()
        #endif
        
        block()
        
        #if PROFILER_ON
        let end = CFAbsoluteTimeGetCurrent()
        Profiler.add(end - start, to: region)
        #endif
    }
    
    static func time(_ iteration: Int, _ block: () -> Void) {
        #if PROFILER_ON
        let start = CFAbsoluteTimeGetCurrent()
        #endif
        
        block()
        
        #if PROFILER_ON
        let end = CFAbsoluteTimeGetCurrent()
        Task(priority: .high) {
            await Profiler.shared.add(end - start, iteration: iteration)
        }
        #endif
    }
    
    static func time<Result>(_ region: CodeRegion, _ block: () -> Result) -> Result {
        #if PROFILER_ON
        let start = CFAbsoluteTimeGetCurrent()
        #endif
        
        let result = block()
        
        #if PROFILER_ON
        let end = CFAbsoluteTimeGetCurrent()
        Profiler.add(end - start, to: region)
        #endif

        return result
    }

    static func report() async {
        #if PROFILER_ON
        /// Wait for everything to finish.
        try! await Task.sleep(nanoseconds: UInt64(1_000_000_000 * 2))
        
        let dict = await Profiler.shared.timing
//        for (region, results) in dict where [.overall, .combineAll, .combine].contains(region) {
            for (region, results) in dict where results.0 > 0 {
            let (count, time) = results
            print("\(region): \(time)s, \(count) (avg \(time / Double(count))s)")
        }
        
        let timingDict = await Profiler.shared.iterationTiming
        for (iteration, results) in timingDict.sortedByKey() {
            let (count, time) = results
            print("\(iteration): \(time)s, \(count) (avg \(time / Double(count))s)")
        }
        #endif
    }
}
