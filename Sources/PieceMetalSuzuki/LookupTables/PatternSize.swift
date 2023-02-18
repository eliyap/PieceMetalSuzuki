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
 This, table width is 6, with 3 points per pixel.
 */
struct PatternSize {
    public let coreSize: PixelSize
    public let tableWidth: Int
    public let pointsPerPixel: UInt32
}
