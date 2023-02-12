//
//  PixelSize.swift
//  
//
//  Created by Secret Asian Man Dev on 12/2/23.
//

import Foundation

struct PixelSize: Equatable, CustomStringConvertible {
    let width: UInt32
    let height: UInt32

    var description: String {
        return "w\(width)h\(height)"
    }
}
