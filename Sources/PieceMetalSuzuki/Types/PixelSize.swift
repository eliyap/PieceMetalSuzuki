//
//  PixelSize.swift
//  
//
//  Created by Secret Asian Man Dev on 12/2/23.
//

import Foundation

public struct PixelSize: Equatable, CustomStringConvertible {
    let width: UInt32
    let height: UInt32

    public var description: String {
        return "w\(width)h\(height)"
    }
}
