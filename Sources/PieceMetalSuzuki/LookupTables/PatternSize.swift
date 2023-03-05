//
//  File.swift
//  
//
//  Created by Secret Asian Man Dev on 18/2/23.
//

import Foundation

/**
 A "pattern" is an arrangement of initial on / off pixels.
 It consists of
 - a core: the pixels we're interested in, which the `Region` covers
 - a perimeter: the immediate surroundings, which inform how this `Region` will combine with adjoining ones.
 
 For example, here's a simple 3x3 pattern, with a 1x1 core:
 ```
 101
 010
 101
 ```
 This pattern produces 4 distinct triads; the most any 3x3 pattern can have.
 Hence, the 3x3 lookup table has 4 columns.
 
 However,  consider the following pattern with a 2x1 core:
 ```
 1001
 0110
 1001
 ```
 Notice the sort of `>-<` shape around the core.
 This has 6 triads across the 2 pixels, the most possible.
 Thus, table width is 6, with 3 points per pixel.
 */
public struct PatternSize {
    public let coreSize: PixelSize
    public let tableWidth: Int
    public let pointsPerPixel: UInt32
    
    public var patternCode: String {
        return "\(coreSize.width)x\(coreSize.height)"
    }
}

extension PatternSize {
    /// Number of rows in the Lookup Table for this pattern.
    var lutHeight: Int {
        /// Including the perimeter adds 2 to the height and width of the core size.
        /// The total number of rows is `2^num_bits`.
        return 1 << Int((coreSize.height + 2) * (coreSize.width + 2))
    }
}

extension PatternSize {
    public static let w1h1 = PatternSize(
        coreSize: PixelSize(width: 1, height: 1),
        tableWidth: 4,
        pointsPerPixel: 4
    )
    
    public static let w2h1 = PatternSize(
        coreSize: PixelSize(width: 2, height: 1),
        tableWidth: 6,
        pointsPerPixel: 3
    )
    
    public static let w2h2 = PatternSize(
        coreSize: PixelSize(width: 2, height: 2),
        tableWidth: 8,
        pointsPerPixel: 2
    )
}
