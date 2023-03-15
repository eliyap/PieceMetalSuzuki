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
 - a perimeter: the immediate surroundings, which inform how this `Region` will combine with adjacent `Region`s
 
 For example, here's a simple 3x3 pattern, with a 1x1 core:
 ```
 101
 010
 101
 ```
 This pattern produces 4 distinct triads; the most any 3x3 pattern can have.
 Hence, the 3x3 lookup table has 4 columns.
 For more information on triads, see paper:
 https://link.springer.com/article/10.1007/s11227-021-04260-y
 
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
public struct PatternSize: Equatable {
    public let coreSize: PixelSize
    public let tableWidth: Int
    public let pointsPerPixel: UInt32
    
    /// Larger patterns have prohibitively large lookup tables.
    /// A 4x4 core size, or 6x6 table, would be gigabytes in size!
    ///
    /// Therefore, a smaller subpattern is matched, and these are combined on the GPU.
    public let subPatternSize: PixelSize
    
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
        /// Densest pattern, 4 triads / 1 pixel, `X` shape.
        /// ```
        /// 101 \ /
        /// 010  X
        /// 101 / \
        /// ```
        pointsPerPixel: 4,
        subPatternSize: PixelSize(width: 1, height: 1)
    )
    
    public static let w2h1 = PatternSize(
        coreSize: PixelSize(width: 2, height: 1),
        tableWidth: 6,
        /// Densest pattern, 6 triads / 2 pixels, `>-<` shape.
        /// ```
        /// 1001 \  /
        /// 0110  ><
        /// 1001 /  \
        /// ```
        pointsPerPixel: 3,
        subPatternSize: PixelSize(width: 2, height: 1)
    )
    
    public static let w2h2 = PatternSize(
        coreSize: PixelSize(width: 2, height: 2),
        tableWidth: 8,
        /// Densest patterns, 8 triads / 4 pixels, `XX` shape, or a big `X`.
        /// ```
        /// 1010 \ ^     1001 \  /
        /// 0101  X >    0110  ++
        /// 1010 < X     0110  ++
        /// 0101  v \    1001 /  \
        /// ```
        pointsPerPixel: 2,
        subPatternSize: PixelSize(width: 2, height: 2)
    )
    
    public static let w4h2 = PatternSize(
        coreSize: PixelSize(width: 4, height: 2),
        tableWidth: 16,
        pointsPerPixel: 2,
        /// 4x2 is the first size with a too-big LUT.
        subPatternSize: PixelSize(width: 2, height: 2)
    )
}
