//
//  File.swift
//  
//
//  Created by Secret Asian Man Dev on 1/3/23.
//

import Foundation
internal func cpuTime() -> TimeInterval {
    Double(clock_gettime_nsec_np(CLOCK_PROCESS_CPUTIME_ID)) / 1_000_000_000
}
