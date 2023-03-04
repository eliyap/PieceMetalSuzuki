//  AutoReleasePoolToken.swift
//  Created by Secret Asian Man Dev on 4/3/23.

import Foundation

/// Verifies that code is called within an `autoreleasepool`
public struct AutoReleasePoolToken {
    fileprivate init() { }
}

func withAutoRelease<Result>(_ block: (AutoReleasePoolToken) throws -> Result) rethrows -> Result {
    try autoreleasepool {
        let token = AutoReleasePoolToken()
        return try block(token)
    }
}
