//  DispatchTask.swift
//  Created by Secret Asian Man Dev on 8/3/23.

import Foundation

/// A dirty hack to run async code synchronously.
/// DO NOT USE, unless you *really want* to use the `Task` model in sync code.
///
/// Used here because
/// - I want the cooperative `Task` model instead of GCD.
/// - I need to call it from `AVCaptureVideoDataOutputSampleBufferDelegate`,
///   which only has synchronous delegate methods.
internal func DispatchTask(priority: TaskPriority? = nil, _ block: @escaping () async throws -> Void) rethrows -> Void {
    let group = DispatchGroup()
    group.enter()
    Task(priority: priority) {
        try await block()
        group.leave()
    }
    group.wait()
}
