//
//  StarterLUT.swift
//  
//
//  Created by Secret Asian Man Dev on 10/2/23.
//

import Foundation

/**
 Using a lookup table to get the initial triads saves on repetitive computation,
 and isn't overly space consuming, since there are only `2^8` distinct kernels (with a 1 in the center).
 
 The table is arranged in rows of 8 values, 4 pairs of directions per row, in the order `(from, to)`
 Rows are left aligned, and 0 padded.
 */
let StarterLUT: [ChainDirection.RawValue] = [
    // 000
    // 0 0
    // 000
    0, 0, 0, 0, 0, 0, 0, 0,

    // 100
    // 0 0
    // 000
    ChainDirection.topLeft.rawValue, ChainDirection.topLeft.rawValue, 0, 0, 0, 0, 0, 0,

    // 010
    // 0 0
    // 000
    ChainDirection.up.rawValue, ChainDirection.up.rawValue, 0, 0, 0, 0, 0, 0,

    // 110
    // 0 0
    // 000
    ChainDirection.up.rawValue, ChainDirection.topLeft.rawValue, 0, 0, 0, 0, 0, 0,

    // 001
    // 0 0
    // 000
    ChainDirection.topRight.rawValue, ChainDirection.topRight.rawValue, 0, 0, 0, 0, 0, 0,

    // 101
    // 0 0
    // 000
    ChainDirection.topRight.rawValue, ChainDirection.topLeft.rawValue, ChainDirection.topLeft.rawValue, ChainDirection.topRight.rawValue, 0, 0, 0, 0,

    // 011
    // 0 0
    // 000
    ChainDirection.topRight.rawValue, ChainDirection.up.rawValue, 0, 0, 0, 0, 0, 0,

    // 111
    // 0 0
    // 000
    ChainDirection.topRight.rawValue, ChainDirection.topLeft.rawValue, 0, 0, 0, 0, 0, 0,

    // 000
    // 1 0
    // 000
    ChainDirection.left.rawValue, ChainDirection.left.rawValue, 0, 0, 0, 0, 0, 0,

    // 100
    // 1 0
    // 000
    ChainDirection.topLeft.rawValue, ChainDirection.left.rawValue, 0, 0, 0, 0, 0, 0,

    // 010
    // 1 0
    // 000
    ChainDirection.up.rawValue, ChainDirection.left.rawValue, 0, 0, 0, 0, 0, 0,

    // 110
    // 1 0
    // 000
    ChainDirection.up.rawValue, ChainDirection.left.rawValue, 0, 0, 0, 0, 0, 0,

    // 001
    // 1 0
    // 000
    ChainDirection.topRight.rawValue, ChainDirection.left.rawValue, ChainDirection.left.rawValue, ChainDirection.topRight.rawValue, 0, 0, 0, 0,

    // 101
    // 1 0
    // 000
    ChainDirection.topRight.rawValue, ChainDirection.left.rawValue, ChainDirection.topLeft.rawValue, ChainDirection.topRight.rawValue, 0, 0, 0, 0,

    // 011
    // 1 0
    // 000
    ChainDirection.topRight.rawValue, ChainDirection.left.rawValue, 0, 0, 0, 0, 0, 0,

    // 111
    // 1 0
    // 000
    ChainDirection.topRight.rawValue, ChainDirection.left.rawValue, 0, 0, 0, 0, 0, 0,

    // 000
    // 0 1
    // 000
    ChainDirection.right.rawValue, ChainDirection.right.rawValue, 0, 0, 0, 0, 0, 0,

    // 100
    // 0 1
    // 000
    ChainDirection.right.rawValue, ChainDirection.topLeft.rawValue, ChainDirection.topLeft.rawValue, ChainDirection.right.rawValue, 0, 0, 0, 0,

    // 010
    // 0 1
    // 000
    ChainDirection.right.rawValue, ChainDirection.up.rawValue, 0, 0, 0, 0, 0, 0,

    // 110
    // 0 1
    // 000
    ChainDirection.right.rawValue, ChainDirection.topLeft.rawValue, 0, 0, 0, 0, 0, 0,

    // 001
    // 0 1
    // 000
    ChainDirection.right.rawValue, ChainDirection.topRight.rawValue, 0, 0, 0, 0, 0, 0,

    // 101
    // 0 1
    // 000
    ChainDirection.right.rawValue, ChainDirection.topLeft.rawValue, ChainDirection.topLeft.rawValue, ChainDirection.topRight.rawValue, 0, 0, 0, 0,

    // 011
    // 0 1
    // 000
    ChainDirection.right.rawValue, ChainDirection.up.rawValue, 0, 0, 0, 0, 0, 0,

    // 111
    // 0 1
    // 000
    ChainDirection.right.rawValue, ChainDirection.topLeft.rawValue, 0, 0, 0, 0, 0, 0,

    // 000
    // 1 1
    // 000
    ChainDirection.right.rawValue, ChainDirection.left.rawValue, ChainDirection.left.rawValue, ChainDirection.right.rawValue, 0, 0, 0, 0,

    // 100
    // 1 1
    // 000
    ChainDirection.right.rawValue, ChainDirection.left.rawValue, ChainDirection.topLeft.rawValue, ChainDirection.right.rawValue, 0, 0, 0, 0,

    // 010
    // 1 1
    // 000
    ChainDirection.right.rawValue, ChainDirection.left.rawValue, 0, 0, 0, 0, 0, 0,

    // 110
    // 1 1
    // 000
    ChainDirection.right.rawValue, ChainDirection.left.rawValue, 0, 0, 0, 0, 0, 0,

    // 001
    // 1 1
    // 000
    ChainDirection.right.rawValue, ChainDirection.left.rawValue, ChainDirection.left.rawValue, ChainDirection.topRight.rawValue, 0, 0, 0, 0,

    // 101
    // 1 1
    // 000
    ChainDirection.right.rawValue, ChainDirection.left.rawValue, ChainDirection.topLeft.rawValue, ChainDirection.topRight.rawValue, 0, 0, 0, 0,

    // 011
    // 1 1
    // 000
    ChainDirection.right.rawValue, ChainDirection.left.rawValue, 0, 0, 0, 0, 0, 0,

    // 111
    // 1 1
    // 000
    ChainDirection.right.rawValue, ChainDirection.left.rawValue, 0, 0, 0, 0, 0, 0,

    // 000
    // 0 0
    // 100
    ChainDirection.bottomLeft.rawValue, ChainDirection.bottomLeft.rawValue, 0, 0, 0, 0, 0, 0,

    // 100
    // 0 0
    // 100
    ChainDirection.bottomLeft.rawValue, ChainDirection.topLeft.rawValue, ChainDirection.topLeft.rawValue, ChainDirection.bottomLeft.rawValue, 0, 0, 0, 0,

    // 010
    // 0 0
    // 100
    ChainDirection.bottomLeft.rawValue, ChainDirection.up.rawValue, ChainDirection.up.rawValue, ChainDirection.bottomLeft.rawValue, 0, 0, 0, 0,

    // 110
    // 0 0
    // 100
    ChainDirection.bottomLeft.rawValue, ChainDirection.topLeft.rawValue, ChainDirection.up.rawValue, ChainDirection.bottomLeft.rawValue, 0, 0, 0, 0,

    // 001
    // 0 0
    // 100
    ChainDirection.topRight.rawValue, ChainDirection.bottomLeft.rawValue, ChainDirection.bottomLeft.rawValue, ChainDirection.topRight.rawValue, 0, 0, 0, 0,

    // 101
    // 0 0
    // 100
    ChainDirection.topRight.rawValue, ChainDirection.bottomLeft.rawValue, ChainDirection.bottomLeft.rawValue, ChainDirection.topLeft.rawValue, ChainDirection.topLeft.rawValue, ChainDirection.topRight.rawValue, 0, 0,

    // 011
    // 0 0
    // 100
    ChainDirection.topRight.rawValue, ChainDirection.bottomLeft.rawValue, ChainDirection.bottomLeft.rawValue, ChainDirection.up.rawValue, 0, 0, 0, 0,

    // 111
    // 0 0
    // 100
    ChainDirection.topRight.rawValue, ChainDirection.bottomLeft.rawValue, ChainDirection.bottomLeft.rawValue, ChainDirection.topLeft.rawValue, 0, 0, 0, 0,

    // 000
    // 1 0
    // 100
    ChainDirection.left.rawValue, ChainDirection.bottomLeft.rawValue, 0, 0, 0, 0, 0, 0,

    // 100
    // 1 0
    // 100
    ChainDirection.topLeft.rawValue, ChainDirection.bottomLeft.rawValue, 0, 0, 0, 0, 0, 0,

    // 010
    // 1 0
    // 100
    ChainDirection.up.rawValue, ChainDirection.bottomLeft.rawValue, 0, 0, 0, 0, 0, 0,

    // 110
    // 1 0
    // 100
    ChainDirection.up.rawValue, ChainDirection.bottomLeft.rawValue, 0, 0, 0, 0, 0, 0,

    // 001
    // 1 0
    // 100
    ChainDirection.topRight.rawValue, ChainDirection.bottomLeft.rawValue, ChainDirection.left.rawValue, ChainDirection.topRight.rawValue, 0, 0, 0, 0,

    // 101
    // 1 0
    // 100
    ChainDirection.topRight.rawValue, ChainDirection.bottomLeft.rawValue, ChainDirection.topLeft.rawValue, ChainDirection.topRight.rawValue, 0, 0, 0, 0,

    // 011
    // 1 0
    // 100
    ChainDirection.topRight.rawValue, ChainDirection.bottomLeft.rawValue, 0, 0, 0, 0, 0, 0,

    // 111
    // 1 0
    // 100
    ChainDirection.topRight.rawValue, ChainDirection.bottomLeft.rawValue, 0, 0, 0, 0, 0, 0,

    // 000
    // 0 1
    // 100
    ChainDirection.right.rawValue, ChainDirection.bottomLeft.rawValue, ChainDirection.bottomLeft.rawValue, ChainDirection.right.rawValue, 0, 0, 0, 0,

    // 100
    // 0 1
    // 100
    ChainDirection.right.rawValue, ChainDirection.bottomLeft.rawValue, ChainDirection.bottomLeft.rawValue, ChainDirection.topLeft.rawValue, ChainDirection.topLeft.rawValue, ChainDirection.right.rawValue, 0, 0,

    // 010
    // 0 1
    // 100
    ChainDirection.right.rawValue, ChainDirection.bottomLeft.rawValue, ChainDirection.bottomLeft.rawValue, ChainDirection.up.rawValue, 0, 0, 0, 0,

    // 110
    // 0 1
    // 100
    ChainDirection.right.rawValue, ChainDirection.bottomLeft.rawValue, ChainDirection.bottomLeft.rawValue, ChainDirection.topLeft.rawValue, 0, 0, 0, 0,

    // 001
    // 0 1
    // 100
    ChainDirection.right.rawValue, ChainDirection.bottomLeft.rawValue, ChainDirection.bottomLeft.rawValue, ChainDirection.topRight.rawValue, 0, 0, 0, 0,

    // 101
    // 0 1
    // 100
    ChainDirection.right.rawValue, ChainDirection.bottomLeft.rawValue, ChainDirection.bottomLeft.rawValue, ChainDirection.topLeft.rawValue, ChainDirection.topLeft.rawValue, ChainDirection.topRight.rawValue, 0, 0,

    // 011
    // 0 1
    // 100
    ChainDirection.right.rawValue, ChainDirection.bottomLeft.rawValue, ChainDirection.bottomLeft.rawValue, ChainDirection.up.rawValue, 0, 0, 0, 0,

    // 111
    // 0 1
    // 100
    ChainDirection.right.rawValue, ChainDirection.bottomLeft.rawValue, ChainDirection.bottomLeft.rawValue, ChainDirection.topLeft.rawValue, 0, 0, 0, 0,

    // 000
    // 1 1
    // 100
    ChainDirection.right.rawValue, ChainDirection.bottomLeft.rawValue, ChainDirection.left.rawValue, ChainDirection.right.rawValue, 0, 0, 0, 0,

    // 100
    // 1 1
    // 100
    ChainDirection.right.rawValue, ChainDirection.bottomLeft.rawValue, ChainDirection.topLeft.rawValue, ChainDirection.right.rawValue, 0, 0, 0, 0,

    // 010
    // 1 1
    // 100
    ChainDirection.right.rawValue, ChainDirection.bottomLeft.rawValue, 0, 0, 0, 0, 0, 0,

    // 110
    // 1 1
    // 100
    ChainDirection.right.rawValue, ChainDirection.bottomLeft.rawValue, 0, 0, 0, 0, 0, 0,

    // 001
    // 1 1
    // 100
    ChainDirection.right.rawValue, ChainDirection.bottomLeft.rawValue, ChainDirection.left.rawValue, ChainDirection.topRight.rawValue, 0, 0, 0, 0,

    // 101
    // 1 1
    // 100
    ChainDirection.right.rawValue, ChainDirection.bottomLeft.rawValue, ChainDirection.topLeft.rawValue, ChainDirection.topRight.rawValue, 0, 0, 0, 0,

    // 011
    // 1 1
    // 100
    ChainDirection.right.rawValue, ChainDirection.bottomLeft.rawValue, 0, 0, 0, 0, 0, 0,

    // 111
    // 1 1
    // 100
    ChainDirection.right.rawValue, ChainDirection.bottomLeft.rawValue, 0, 0, 0, 0, 0, 0,

    // 000
    // 0 0
    // 010
    ChainDirection.down.rawValue, ChainDirection.down.rawValue, 0, 0, 0, 0, 0, 0,

    // 100
    // 0 0
    // 010
    ChainDirection.down.rawValue, ChainDirection.topLeft.rawValue, ChainDirection.topLeft.rawValue, ChainDirection.down.rawValue, 0, 0, 0, 0,

    // 010
    // 0 0
    // 010
    ChainDirection.down.rawValue, ChainDirection.up.rawValue, ChainDirection.up.rawValue, ChainDirection.down.rawValue, 0, 0, 0, 0,

    // 110
    // 0 0
    // 010
    ChainDirection.down.rawValue, ChainDirection.topLeft.rawValue, ChainDirection.up.rawValue, ChainDirection.down.rawValue, 0, 0, 0, 0,

    // 001
    // 0 0
    // 010
    ChainDirection.topRight.rawValue, ChainDirection.down.rawValue, ChainDirection.down.rawValue, ChainDirection.topRight.rawValue, 0, 0, 0, 0,

    // 101
    // 0 0
    // 010
    ChainDirection.topRight.rawValue, ChainDirection.down.rawValue, ChainDirection.down.rawValue, ChainDirection.topLeft.rawValue, ChainDirection.topLeft.rawValue, ChainDirection.topRight.rawValue, 0, 0,

    // 011
    // 0 0
    // 010
    ChainDirection.topRight.rawValue, ChainDirection.down.rawValue, ChainDirection.down.rawValue, ChainDirection.up.rawValue, 0, 0, 0, 0,

    // 111
    // 0 0
    // 010
    ChainDirection.topRight.rawValue, ChainDirection.down.rawValue, ChainDirection.down.rawValue, ChainDirection.topLeft.rawValue, 0, 0, 0, 0,

    // 000
    // 1 0
    // 010
    ChainDirection.left.rawValue, ChainDirection.down.rawValue, 0, 0, 0, 0, 0, 0,

    // 100
    // 1 0
    // 010
    ChainDirection.topLeft.rawValue, ChainDirection.down.rawValue, 0, 0, 0, 0, 0, 0,

    // 010
    // 1 0
    // 010
    ChainDirection.up.rawValue, ChainDirection.down.rawValue, 0, 0, 0, 0, 0, 0,

    // 110
    // 1 0
    // 010
    ChainDirection.up.rawValue, ChainDirection.down.rawValue, 0, 0, 0, 0, 0, 0,

    // 001
    // 1 0
    // 010
    ChainDirection.topRight.rawValue, ChainDirection.down.rawValue, ChainDirection.left.rawValue, ChainDirection.topRight.rawValue, 0, 0, 0, 0,

    // 101
    // 1 0
    // 010
    ChainDirection.topRight.rawValue, ChainDirection.down.rawValue, ChainDirection.topLeft.rawValue, ChainDirection.topRight.rawValue, 0, 0, 0, 0,

    // 011
    // 1 0
    // 010
    ChainDirection.topRight.rawValue, ChainDirection.down.rawValue, 0, 0, 0, 0, 0, 0,

    // 111
    // 1 0
    // 010
    ChainDirection.topRight.rawValue, ChainDirection.down.rawValue, 0, 0, 0, 0, 0, 0,

    // 000
    // 0 1
    // 010
    ChainDirection.down.rawValue, ChainDirection.right.rawValue, 0, 0, 0, 0, 0, 0,

    // 100
    // 0 1
    // 010
    ChainDirection.down.rawValue, ChainDirection.topLeft.rawValue, ChainDirection.topLeft.rawValue, ChainDirection.right.rawValue, 0, 0, 0, 0,

    // 010
    // 0 1
    // 010
    ChainDirection.down.rawValue, ChainDirection.up.rawValue, 0, 0, 0, 0, 0, 0,

    // 110
    // 0 1
    // 010
    ChainDirection.down.rawValue, ChainDirection.topLeft.rawValue, 0, 0, 0, 0, 0, 0,

    // 001
    // 0 1
    // 010
    ChainDirection.down.rawValue, ChainDirection.topRight.rawValue, 0, 0, 0, 0, 0, 0,

    // 101
    // 0 1
    // 010
    ChainDirection.down.rawValue, ChainDirection.topLeft.rawValue, ChainDirection.topLeft.rawValue, ChainDirection.topRight.rawValue, 0, 0, 0, 0,

    // 011
    // 0 1
    // 010
    ChainDirection.down.rawValue, ChainDirection.up.rawValue, 0, 0, 0, 0, 0, 0,

    // 111
    // 0 1
    // 010
    ChainDirection.down.rawValue, ChainDirection.topLeft.rawValue, 0, 0, 0, 0, 0, 0,

    // 000
    // 1 1
    // 010
    ChainDirection.left.rawValue, ChainDirection.right.rawValue, 0, 0, 0, 0, 0, 0,

    // 100
    // 1 1
    // 010
    ChainDirection.topLeft.rawValue, ChainDirection.right.rawValue, 0, 0, 0, 0, 0, 0,

    // 010
    // 1 1
    // 010
    0, 0, 0, 0, 0, 0, 0, 0,

    // 110
    // 1 1
    // 010
    0, 0, 0, 0, 0, 0, 0, 0,

    // 001
    // 1 1
    // 010
    ChainDirection.left.rawValue, ChainDirection.topRight.rawValue, 0, 0, 0, 0, 0, 0,

    // 101
    // 1 1
    // 010
    ChainDirection.topLeft.rawValue, ChainDirection.topRight.rawValue, 0, 0, 0, 0, 0, 0,

    // 011
    // 1 1
    // 010
    0, 0, 0, 0, 0, 0, 0, 0,

    // 111
    // 1 1
    // 010
    0, 0, 0, 0, 0, 0, 0, 0,

    // 000
    // 0 0
    // 110
    ChainDirection.bottomLeft.rawValue, ChainDirection.down.rawValue, 0, 0, 0, 0, 0, 0,

    // 100
    // 0 0
    // 110
    ChainDirection.bottomLeft.rawValue, ChainDirection.topLeft.rawValue, ChainDirection.topLeft.rawValue, ChainDirection.down.rawValue, 0, 0, 0, 0,

    // 010
    // 0 0
    // 110
    ChainDirection.bottomLeft.rawValue, ChainDirection.up.rawValue, ChainDirection.up.rawValue, ChainDirection.down.rawValue, 0, 0, 0, 0,

    // 110
    // 0 0
    // 110
    ChainDirection.bottomLeft.rawValue, ChainDirection.topLeft.rawValue, ChainDirection.up.rawValue, ChainDirection.down.rawValue, 0, 0, 0, 0,

    // 001
    // 0 0
    // 110
    ChainDirection.topRight.rawValue, ChainDirection.down.rawValue, ChainDirection.bottomLeft.rawValue, ChainDirection.topRight.rawValue, 0, 0, 0, 0,

    // 101
    // 0 0
    // 110
    ChainDirection.topRight.rawValue, ChainDirection.down.rawValue, ChainDirection.bottomLeft.rawValue, ChainDirection.topLeft.rawValue, ChainDirection.topLeft.rawValue, ChainDirection.topRight.rawValue, 0, 0,

    // 011
    // 0 0
    // 110
    ChainDirection.topRight.rawValue, ChainDirection.down.rawValue, ChainDirection.bottomLeft.rawValue, ChainDirection.up.rawValue, 0, 0, 0, 0,

    // 111
    // 0 0
    // 110
    ChainDirection.topRight.rawValue, ChainDirection.down.rawValue, ChainDirection.bottomLeft.rawValue, ChainDirection.topLeft.rawValue, 0, 0, 0, 0,

    // 000
    // 1 0
    // 110
    ChainDirection.left.rawValue, ChainDirection.down.rawValue, 0, 0, 0, 0, 0, 0,

    // 100
    // 1 0
    // 110
    ChainDirection.topLeft.rawValue, ChainDirection.down.rawValue, 0, 0, 0, 0, 0, 0,

    // 010
    // 1 0
    // 110
    ChainDirection.up.rawValue, ChainDirection.down.rawValue, 0, 0, 0, 0, 0, 0,

    // 110
    // 1 0
    // 110
    ChainDirection.up.rawValue, ChainDirection.down.rawValue, 0, 0, 0, 0, 0, 0,

    // 001
    // 1 0
    // 110
    ChainDirection.topRight.rawValue, ChainDirection.down.rawValue, ChainDirection.left.rawValue, ChainDirection.topRight.rawValue, 0, 0, 0, 0,

    // 101
    // 1 0
    // 110
    ChainDirection.topRight.rawValue, ChainDirection.down.rawValue, ChainDirection.topLeft.rawValue, ChainDirection.topRight.rawValue, 0, 0, 0, 0,

    // 011
    // 1 0
    // 110
    ChainDirection.topRight.rawValue, ChainDirection.down.rawValue, 0, 0, 0, 0, 0, 0,

    // 111
    // 1 0
    // 110
    ChainDirection.topRight.rawValue, ChainDirection.down.rawValue, 0, 0, 0, 0, 0, 0,

    // 000
    // 0 1
    // 110
    ChainDirection.bottomLeft.rawValue, ChainDirection.right.rawValue, 0, 0, 0, 0, 0, 0,

    // 100
    // 0 1
    // 110
    ChainDirection.bottomLeft.rawValue, ChainDirection.topLeft.rawValue, ChainDirection.topLeft.rawValue, ChainDirection.right.rawValue, 0, 0, 0, 0,

    // 010
    // 0 1
    // 110
    ChainDirection.bottomLeft.rawValue, ChainDirection.up.rawValue, 0, 0, 0, 0, 0, 0,

    // 110
    // 0 1
    // 110
    ChainDirection.bottomLeft.rawValue, ChainDirection.topLeft.rawValue, 0, 0, 0, 0, 0, 0,

    // 001
    // 0 1
    // 110
    ChainDirection.bottomLeft.rawValue, ChainDirection.topRight.rawValue, 0, 0, 0, 0, 0, 0,

    // 101
    // 0 1
    // 110
    ChainDirection.bottomLeft.rawValue, ChainDirection.topLeft.rawValue, ChainDirection.topLeft.rawValue, ChainDirection.topRight.rawValue, 0, 0, 0, 0,

    // 011
    // 0 1
    // 110
    ChainDirection.bottomLeft.rawValue, ChainDirection.up.rawValue, 0, 0, 0, 0, 0, 0,

    // 111
    // 0 1
    // 110
    ChainDirection.bottomLeft.rawValue, ChainDirection.topLeft.rawValue, 0, 0, 0, 0, 0, 0,

    // 000
    // 1 1
    // 110
    ChainDirection.left.rawValue, ChainDirection.right.rawValue, 0, 0, 0, 0, 0, 0,

    // 100
    // 1 1
    // 110
    ChainDirection.topLeft.rawValue, ChainDirection.right.rawValue, 0, 0, 0, 0, 0, 0,

    // 010
    // 1 1
    // 110
    0, 0, 0, 0, 0, 0, 0, 0,

    // 110
    // 1 1
    // 110
    0, 0, 0, 0, 0, 0, 0, 0,

    // 001
    // 1 1
    // 110
    ChainDirection.left.rawValue, ChainDirection.topRight.rawValue, 0, 0, 0, 0, 0, 0,

    // 101
    // 1 1
    // 110
    ChainDirection.topLeft.rawValue, ChainDirection.topRight.rawValue, 0, 0, 0, 0, 0, 0,

    // 011
    // 1 1
    // 110
    0, 0, 0, 0, 0, 0, 0, 0,

    // 111
    // 1 1
    // 110
    0, 0, 0, 0, 0, 0, 0, 0,

    // 000
    // 0 0
    // 001
    ChainDirection.bottomRight.rawValue, ChainDirection.bottomRight.rawValue, 0, 0, 0, 0, 0, 0,

    // 100
    // 0 0
    // 001
    ChainDirection.bottomRight.rawValue, ChainDirection.topLeft.rawValue, ChainDirection.topLeft.rawValue, ChainDirection.bottomRight.rawValue, 0, 0, 0, 0,

    // 010
    // 0 0
    // 001
    ChainDirection.bottomRight.rawValue, ChainDirection.up.rawValue, ChainDirection.up.rawValue, ChainDirection.bottomRight.rawValue, 0, 0, 0, 0,

    // 110
    // 0 0
    // 001
    ChainDirection.bottomRight.rawValue, ChainDirection.topLeft.rawValue, ChainDirection.up.rawValue, ChainDirection.bottomRight.rawValue, 0, 0, 0, 0,

    // 001
    // 0 0
    // 001
    ChainDirection.topRight.rawValue, ChainDirection.bottomRight.rawValue, ChainDirection.bottomRight.rawValue, ChainDirection.topRight.rawValue, 0, 0, 0, 0,

    // 101
    // 0 0
    // 001
    ChainDirection.topRight.rawValue, ChainDirection.bottomRight.rawValue, ChainDirection.bottomRight.rawValue, ChainDirection.topLeft.rawValue, ChainDirection.topLeft.rawValue, ChainDirection.topRight.rawValue, 0, 0,

    // 011
    // 0 0
    // 001
    ChainDirection.topRight.rawValue, ChainDirection.bottomRight.rawValue, ChainDirection.bottomRight.rawValue, ChainDirection.up.rawValue, 0, 0, 0, 0,

    // 111
    // 0 0
    // 001
    ChainDirection.topRight.rawValue, ChainDirection.bottomRight.rawValue, ChainDirection.bottomRight.rawValue, ChainDirection.topLeft.rawValue, 0, 0, 0, 0,

    // 000
    // 1 0
    // 001
    ChainDirection.bottomRight.rawValue, ChainDirection.left.rawValue, ChainDirection.left.rawValue, ChainDirection.bottomRight.rawValue, 0, 0, 0, 0,

    // 100
    // 1 0
    // 001
    ChainDirection.bottomRight.rawValue, ChainDirection.left.rawValue, ChainDirection.topLeft.rawValue, ChainDirection.bottomRight.rawValue, 0, 0, 0, 0,

    // 010
    // 1 0
    // 001
    ChainDirection.bottomRight.rawValue, ChainDirection.left.rawValue, ChainDirection.up.rawValue, ChainDirection.bottomRight.rawValue, 0, 0, 0, 0,

    // 110
    // 1 0
    // 001
    ChainDirection.bottomRight.rawValue, ChainDirection.left.rawValue, ChainDirection.up.rawValue, ChainDirection.bottomRight.rawValue, 0, 0, 0, 0,

    // 001
    // 1 0
    // 001
    ChainDirection.topRight.rawValue, ChainDirection.bottomRight.rawValue, ChainDirection.bottomRight.rawValue, ChainDirection.left.rawValue, ChainDirection.left.rawValue, ChainDirection.topRight.rawValue, 0, 0,

    // 101
    // 1 0
    // 001
    ChainDirection.topRight.rawValue, ChainDirection.bottomRight.rawValue, ChainDirection.bottomRight.rawValue, ChainDirection.left.rawValue, ChainDirection.topLeft.rawValue, ChainDirection.topRight.rawValue, 0, 0,

    // 011
    // 1 0
    // 001
    ChainDirection.topRight.rawValue, ChainDirection.bottomRight.rawValue, ChainDirection.bottomRight.rawValue, ChainDirection.left.rawValue, 0, 0, 0, 0,

    // 111
    // 1 0
    // 001
    ChainDirection.topRight.rawValue, ChainDirection.bottomRight.rawValue, ChainDirection.bottomRight.rawValue, ChainDirection.left.rawValue, 0, 0, 0, 0,

    // 000
    // 0 1
    // 001
    ChainDirection.bottomRight.rawValue, ChainDirection.right.rawValue, 0, 0, 0, 0, 0, 0,

    // 100
    // 0 1
    // 001
    ChainDirection.bottomRight.rawValue, ChainDirection.topLeft.rawValue, ChainDirection.topLeft.rawValue, ChainDirection.right.rawValue, 0, 0, 0, 0,

    // 010
    // 0 1
    // 001
    ChainDirection.bottomRight.rawValue, ChainDirection.up.rawValue, 0, 0, 0, 0, 0, 0,

    // 110
    // 0 1
    // 001
    ChainDirection.bottomRight.rawValue, ChainDirection.topLeft.rawValue, 0, 0, 0, 0, 0, 0,

    // 001
    // 0 1
    // 001
    ChainDirection.bottomRight.rawValue, ChainDirection.topRight.rawValue, 0, 0, 0, 0, 0, 0,

    // 101
    // 0 1
    // 001
    ChainDirection.bottomRight.rawValue, ChainDirection.topLeft.rawValue, ChainDirection.topLeft.rawValue, ChainDirection.topRight.rawValue, 0, 0, 0, 0,

    // 011
    // 0 1
    // 001
    ChainDirection.bottomRight.rawValue, ChainDirection.up.rawValue, 0, 0, 0, 0, 0, 0,

    // 111
    // 0 1
    // 001
    ChainDirection.bottomRight.rawValue, ChainDirection.topLeft.rawValue, 0, 0, 0, 0, 0, 0,

    // 000
    // 1 1
    // 001
    ChainDirection.bottomRight.rawValue, ChainDirection.left.rawValue, ChainDirection.left.rawValue, ChainDirection.right.rawValue, 0, 0, 0, 0,

    // 100
    // 1 1
    // 001
    ChainDirection.bottomRight.rawValue, ChainDirection.left.rawValue, ChainDirection.topLeft.rawValue, ChainDirection.right.rawValue, 0, 0, 0, 0,

    // 010
    // 1 1
    // 001
    ChainDirection.bottomRight.rawValue, ChainDirection.left.rawValue, 0, 0, 0, 0, 0, 0,

    // 110
    // 1 1
    // 001
    ChainDirection.bottomRight.rawValue, ChainDirection.left.rawValue, 0, 0, 0, 0, 0, 0,

    // 001
    // 1 1
    // 001
    ChainDirection.bottomRight.rawValue, ChainDirection.left.rawValue, ChainDirection.left.rawValue, ChainDirection.topRight.rawValue, 0, 0, 0, 0,

    // 101
    // 1 1
    // 001
    ChainDirection.bottomRight.rawValue, ChainDirection.left.rawValue, ChainDirection.topLeft.rawValue, ChainDirection.topRight.rawValue, 0, 0, 0, 0,

    // 011
    // 1 1
    // 001
    ChainDirection.bottomRight.rawValue, ChainDirection.left.rawValue, 0, 0, 0, 0, 0, 0,

    // 111
    // 1 1
    // 001
    ChainDirection.bottomRight.rawValue, ChainDirection.left.rawValue, 0, 0, 0, 0, 0, 0,

    // 000
    // 0 0
    // 101
    ChainDirection.bottomRight.rawValue, ChainDirection.bottomLeft.rawValue, ChainDirection.bottomLeft.rawValue, ChainDirection.bottomRight.rawValue, 0, 0, 0, 0,

    // 100
    // 0 0
    // 101
    ChainDirection.bottomRight.rawValue, ChainDirection.bottomLeft.rawValue, ChainDirection.bottomLeft.rawValue, ChainDirection.topLeft.rawValue, ChainDirection.topLeft.rawValue, ChainDirection.bottomRight.rawValue, 0, 0,

    // 010
    // 0 0
    // 101
    ChainDirection.bottomRight.rawValue, ChainDirection.bottomLeft.rawValue, ChainDirection.bottomLeft.rawValue, ChainDirection.up.rawValue, ChainDirection.up.rawValue, ChainDirection.bottomRight.rawValue, 0, 0,

    // 110
    // 0 0
    // 101
    ChainDirection.bottomRight.rawValue, ChainDirection.bottomLeft.rawValue, ChainDirection.bottomLeft.rawValue, ChainDirection.topLeft.rawValue, ChainDirection.up.rawValue, ChainDirection.bottomRight.rawValue, 0, 0,

    // 001
    // 0 0
    // 101
    ChainDirection.topRight.rawValue, ChainDirection.bottomRight.rawValue, ChainDirection.bottomRight.rawValue, ChainDirection.bottomLeft.rawValue, ChainDirection.bottomLeft.rawValue, ChainDirection.topRight.rawValue, 0, 0,

    // 101
    // 0 0
    // 101
    ChainDirection.topRight.rawValue, ChainDirection.bottomRight.rawValue, ChainDirection.bottomRight.rawValue, ChainDirection.bottomLeft.rawValue, ChainDirection.bottomLeft.rawValue, ChainDirection.topLeft.rawValue, ChainDirection.topLeft.rawValue, ChainDirection.topRight.rawValue,

    // 011
    // 0 0
    // 101
    ChainDirection.topRight.rawValue, ChainDirection.bottomRight.rawValue, ChainDirection.bottomRight.rawValue, ChainDirection.bottomLeft.rawValue, ChainDirection.bottomLeft.rawValue, ChainDirection.up.rawValue, 0, 0,

    // 111
    // 0 0
    // 101
    ChainDirection.topRight.rawValue, ChainDirection.bottomRight.rawValue, ChainDirection.bottomRight.rawValue, ChainDirection.bottomLeft.rawValue, ChainDirection.bottomLeft.rawValue, ChainDirection.topLeft.rawValue, 0, 0,

    // 000
    // 1 0
    // 101
    ChainDirection.bottomRight.rawValue, ChainDirection.bottomLeft.rawValue, ChainDirection.left.rawValue, ChainDirection.bottomRight.rawValue, 0, 0, 0, 0,

    // 100
    // 1 0
    // 101
    ChainDirection.bottomRight.rawValue, ChainDirection.bottomLeft.rawValue, ChainDirection.topLeft.rawValue, ChainDirection.bottomRight.rawValue, 0, 0, 0, 0,

    // 010
    // 1 0
    // 101
    ChainDirection.bottomRight.rawValue, ChainDirection.bottomLeft.rawValue, ChainDirection.up.rawValue, ChainDirection.bottomRight.rawValue, 0, 0, 0, 0,

    // 110
    // 1 0
    // 101
    ChainDirection.bottomRight.rawValue, ChainDirection.bottomLeft.rawValue, ChainDirection.up.rawValue, ChainDirection.bottomRight.rawValue, 0, 0, 0, 0,

    // 001
    // 1 0
    // 101
    ChainDirection.topRight.rawValue, ChainDirection.bottomRight.rawValue, ChainDirection.bottomRight.rawValue, ChainDirection.bottomLeft.rawValue, ChainDirection.left.rawValue, ChainDirection.topRight.rawValue, 0, 0,

    // 101
    // 1 0
    // 101
    ChainDirection.topRight.rawValue, ChainDirection.bottomRight.rawValue, ChainDirection.bottomRight.rawValue, ChainDirection.bottomLeft.rawValue, ChainDirection.topLeft.rawValue, ChainDirection.topRight.rawValue, 0, 0,

    // 011
    // 1 0
    // 101
    ChainDirection.topRight.rawValue, ChainDirection.bottomRight.rawValue, ChainDirection.bottomRight.rawValue, ChainDirection.bottomLeft.rawValue, 0, 0, 0, 0,

    // 111
    // 1 0
    // 101
    ChainDirection.topRight.rawValue, ChainDirection.bottomRight.rawValue, ChainDirection.bottomRight.rawValue, ChainDirection.bottomLeft.rawValue, 0, 0, 0, 0,

    // 000
    // 0 1
    // 101
    ChainDirection.bottomRight.rawValue, ChainDirection.bottomLeft.rawValue, ChainDirection.bottomLeft.rawValue, ChainDirection.right.rawValue, 0, 0, 0, 0,

    // 100
    // 0 1
    // 101
    ChainDirection.bottomRight.rawValue, ChainDirection.bottomLeft.rawValue, ChainDirection.bottomLeft.rawValue, ChainDirection.topLeft.rawValue, ChainDirection.topLeft.rawValue, ChainDirection.right.rawValue, 0, 0,

    // 010
    // 0 1
    // 101
    ChainDirection.bottomRight.rawValue, ChainDirection.bottomLeft.rawValue, ChainDirection.bottomLeft.rawValue, ChainDirection.up.rawValue, 0, 0, 0, 0,

    // 110
    // 0 1
    // 101
    ChainDirection.bottomRight.rawValue, ChainDirection.bottomLeft.rawValue, ChainDirection.bottomLeft.rawValue, ChainDirection.topLeft.rawValue, 0, 0, 0, 0,

    // 001
    // 0 1
    // 101
    ChainDirection.bottomRight.rawValue, ChainDirection.bottomLeft.rawValue, ChainDirection.bottomLeft.rawValue, ChainDirection.topRight.rawValue, 0, 0, 0, 0,

    // 101
    // 0 1
    // 101
    ChainDirection.bottomRight.rawValue, ChainDirection.bottomLeft.rawValue, ChainDirection.bottomLeft.rawValue, ChainDirection.topLeft.rawValue, ChainDirection.topLeft.rawValue, ChainDirection.topRight.rawValue, 0, 0,

    // 011
    // 0 1
    // 101
    ChainDirection.bottomRight.rawValue, ChainDirection.bottomLeft.rawValue, ChainDirection.bottomLeft.rawValue, ChainDirection.up.rawValue, 0, 0, 0, 0,

    // 111
    // 0 1
    // 101
    ChainDirection.bottomRight.rawValue, ChainDirection.bottomLeft.rawValue, ChainDirection.bottomLeft.rawValue, ChainDirection.topLeft.rawValue, 0, 0, 0, 0,

    // 000
    // 1 1
    // 101
    ChainDirection.bottomRight.rawValue, ChainDirection.bottomLeft.rawValue, ChainDirection.left.rawValue, ChainDirection.right.rawValue, 0, 0, 0, 0,

    // 100
    // 1 1
    // 101
    ChainDirection.bottomRight.rawValue, ChainDirection.bottomLeft.rawValue, ChainDirection.topLeft.rawValue, ChainDirection.right.rawValue, 0, 0, 0, 0,

    // 010
    // 1 1
    // 101
    ChainDirection.bottomRight.rawValue, ChainDirection.bottomLeft.rawValue, 0, 0, 0, 0, 0, 0,

    // 110
    // 1 1
    // 101
    ChainDirection.bottomRight.rawValue, ChainDirection.bottomLeft.rawValue, 0, 0, 0, 0, 0, 0,

    // 001
    // 1 1
    // 101
    ChainDirection.bottomRight.rawValue, ChainDirection.bottomLeft.rawValue, ChainDirection.left.rawValue, ChainDirection.topRight.rawValue, 0, 0, 0, 0,

    // 101
    // 1 1
    // 101
    ChainDirection.bottomRight.rawValue, ChainDirection.bottomLeft.rawValue, ChainDirection.topLeft.rawValue, ChainDirection.topRight.rawValue, 0, 0, 0, 0,

    // 011
    // 1 1
    // 101
    ChainDirection.bottomRight.rawValue, ChainDirection.bottomLeft.rawValue, 0, 0, 0, 0, 0, 0,

    // 111
    // 1 1
    // 101
    ChainDirection.bottomRight.rawValue, ChainDirection.bottomLeft.rawValue, 0, 0, 0, 0, 0, 0,

    // 000
    // 0 0
    // 011
    ChainDirection.down.rawValue, ChainDirection.bottomRight.rawValue, 0, 0, 0, 0, 0, 0,

    // 100
    // 0 0
    // 011
    ChainDirection.down.rawValue, ChainDirection.topLeft.rawValue, ChainDirection.topLeft.rawValue, ChainDirection.bottomRight.rawValue, 0, 0, 0, 0,

    // 010
    // 0 0
    // 011
    ChainDirection.down.rawValue, ChainDirection.up.rawValue, ChainDirection.up.rawValue, ChainDirection.bottomRight.rawValue, 0, 0, 0, 0,

    // 110
    // 0 0
    // 011
    ChainDirection.down.rawValue, ChainDirection.topLeft.rawValue, ChainDirection.up.rawValue, ChainDirection.bottomRight.rawValue, 0, 0, 0, 0,

    // 001
    // 0 0
    // 011
    ChainDirection.topRight.rawValue, ChainDirection.bottomRight.rawValue, ChainDirection.down.rawValue, ChainDirection.topRight.rawValue, 0, 0, 0, 0,

    // 101
    // 0 0
    // 011
    ChainDirection.topRight.rawValue, ChainDirection.bottomRight.rawValue, ChainDirection.down.rawValue, ChainDirection.topLeft.rawValue, ChainDirection.topLeft.rawValue, ChainDirection.topRight.rawValue, 0, 0,

    // 011
    // 0 0
    // 011
    ChainDirection.topRight.rawValue, ChainDirection.bottomRight.rawValue, ChainDirection.down.rawValue, ChainDirection.up.rawValue, 0, 0, 0, 0,

    // 111
    // 0 0
    // 011
    ChainDirection.topRight.rawValue, ChainDirection.bottomRight.rawValue, ChainDirection.down.rawValue, ChainDirection.topLeft.rawValue, 0, 0, 0, 0,

    // 000
    // 1 0
    // 011
    ChainDirection.left.rawValue, ChainDirection.bottomRight.rawValue, 0, 0, 0, 0, 0, 0,

    // 100
    // 1 0
    // 011
    ChainDirection.topLeft.rawValue, ChainDirection.bottomRight.rawValue, 0, 0, 0, 0, 0, 0,

    // 010
    // 1 0
    // 011
    ChainDirection.up.rawValue, ChainDirection.bottomRight.rawValue, 0, 0, 0, 0, 0, 0,

    // 110
    // 1 0
    // 011
    ChainDirection.up.rawValue, ChainDirection.bottomRight.rawValue, 0, 0, 0, 0, 0, 0,

    // 001
    // 1 0
    // 011
    ChainDirection.topRight.rawValue, ChainDirection.bottomRight.rawValue, ChainDirection.left.rawValue, ChainDirection.topRight.rawValue, 0, 0, 0, 0,

    // 101
    // 1 0
    // 011
    ChainDirection.topRight.rawValue, ChainDirection.bottomRight.rawValue, ChainDirection.topLeft.rawValue, ChainDirection.topRight.rawValue, 0, 0, 0, 0,

    // 011
    // 1 0
    // 011
    ChainDirection.topRight.rawValue, ChainDirection.bottomRight.rawValue, 0, 0, 0, 0, 0, 0,

    // 111
    // 1 0
    // 011
    ChainDirection.topRight.rawValue, ChainDirection.bottomRight.rawValue, 0, 0, 0, 0, 0, 0,

    // 000
    // 0 1
    // 011
    ChainDirection.down.rawValue, ChainDirection.right.rawValue, 0, 0, 0, 0, 0, 0,

    // 100
    // 0 1
    // 011
    ChainDirection.down.rawValue, ChainDirection.topLeft.rawValue, ChainDirection.topLeft.rawValue, ChainDirection.right.rawValue, 0, 0, 0, 0,

    // 010
    // 0 1
    // 011
    ChainDirection.down.rawValue, ChainDirection.up.rawValue, 0, 0, 0, 0, 0, 0,

    // 110
    // 0 1
    // 011
    ChainDirection.down.rawValue, ChainDirection.topLeft.rawValue, 0, 0, 0, 0, 0, 0,

    // 001
    // 0 1
    // 011
    ChainDirection.down.rawValue, ChainDirection.topRight.rawValue, 0, 0, 0, 0, 0, 0,

    // 101
    // 0 1
    // 011
    ChainDirection.down.rawValue, ChainDirection.topLeft.rawValue, ChainDirection.topLeft.rawValue, ChainDirection.topRight.rawValue, 0, 0, 0, 0,

    // 011
    // 0 1
    // 011
    ChainDirection.down.rawValue, ChainDirection.up.rawValue, 0, 0, 0, 0, 0, 0,

    // 111
    // 0 1
    // 011
    ChainDirection.down.rawValue, ChainDirection.topLeft.rawValue, 0, 0, 0, 0, 0, 0,

    // 000
    // 1 1
    // 011
    ChainDirection.left.rawValue, ChainDirection.right.rawValue, 0, 0, 0, 0, 0, 0,

    // 100
    // 1 1
    // 011
    ChainDirection.topLeft.rawValue, ChainDirection.right.rawValue, 0, 0, 0, 0, 0, 0,

    // 010
    // 1 1
    // 011
    0, 0, 0, 0, 0, 0, 0, 0,

    // 110
    // 1 1
    // 011
    0, 0, 0, 0, 0, 0, 0, 0,

    // 001
    // 1 1
    // 011
    ChainDirection.left.rawValue, ChainDirection.topRight.rawValue, 0, 0, 0, 0, 0, 0,

    // 101
    // 1 1
    // 011
    ChainDirection.topLeft.rawValue, ChainDirection.topRight.rawValue, 0, 0, 0, 0, 0, 0,

    // 011
    // 1 1
    // 011
    0, 0, 0, 0, 0, 0, 0, 0,

    // 111
    // 1 1
    // 011
    0, 0, 0, 0, 0, 0, 0, 0,

    // 000
    // 0 0
    // 111
    ChainDirection.bottomLeft.rawValue, ChainDirection.bottomRight.rawValue, 0, 0, 0, 0, 0, 0,

    // 100
    // 0 0
    // 111
    ChainDirection.bottomLeft.rawValue, ChainDirection.topLeft.rawValue, ChainDirection.topLeft.rawValue, ChainDirection.bottomRight.rawValue, 0, 0, 0, 0,

    // 010
    // 0 0
    // 111
    ChainDirection.bottomLeft.rawValue, ChainDirection.up.rawValue, ChainDirection.up.rawValue, ChainDirection.bottomRight.rawValue, 0, 0, 0, 0,

    // 110
    // 0 0
    // 111
    ChainDirection.bottomLeft.rawValue, ChainDirection.topLeft.rawValue, ChainDirection.up.rawValue, ChainDirection.bottomRight.rawValue, 0, 0, 0, 0,

    // 001
    // 0 0
    // 111
    ChainDirection.topRight.rawValue, ChainDirection.bottomRight.rawValue, ChainDirection.bottomLeft.rawValue, ChainDirection.topRight.rawValue, 0, 0, 0, 0,

    // 101
    // 0 0
    // 111
    ChainDirection.topRight.rawValue, ChainDirection.bottomRight.rawValue, ChainDirection.bottomLeft.rawValue, ChainDirection.topLeft.rawValue, ChainDirection.topLeft.rawValue, ChainDirection.topRight.rawValue, 0, 0,

    // 011
    // 0 0
    // 111
    ChainDirection.topRight.rawValue, ChainDirection.bottomRight.rawValue, ChainDirection.bottomLeft.rawValue, ChainDirection.up.rawValue, 0, 0, 0, 0,

    // 111
    // 0 0
    // 111
    ChainDirection.topRight.rawValue, ChainDirection.bottomRight.rawValue, ChainDirection.bottomLeft.rawValue, ChainDirection.topLeft.rawValue, 0, 0, 0, 0,

    // 000
    // 1 0
    // 111
    ChainDirection.left.rawValue, ChainDirection.bottomRight.rawValue, 0, 0, 0, 0, 0, 0,

    // 100
    // 1 0
    // 111
    ChainDirection.topLeft.rawValue, ChainDirection.bottomRight.rawValue, 0, 0, 0, 0, 0, 0,

    // 010
    // 1 0
    // 111
    ChainDirection.up.rawValue, ChainDirection.bottomRight.rawValue, 0, 0, 0, 0, 0, 0,

    // 110
    // 1 0
    // 111
    ChainDirection.up.rawValue, ChainDirection.bottomRight.rawValue, 0, 0, 0, 0, 0, 0,

    // 001
    // 1 0
    // 111
    ChainDirection.topRight.rawValue, ChainDirection.bottomRight.rawValue, ChainDirection.left.rawValue, ChainDirection.topRight.rawValue, 0, 0, 0, 0,

    // 101
    // 1 0
    // 111
    ChainDirection.topRight.rawValue, ChainDirection.bottomRight.rawValue, ChainDirection.topLeft.rawValue, ChainDirection.topRight.rawValue, 0, 0, 0, 0,

    // 011
    // 1 0
    // 111
    ChainDirection.topRight.rawValue, ChainDirection.bottomRight.rawValue, 0, 0, 0, 0, 0, 0,

    // 111
    // 1 0
    // 111
    ChainDirection.topRight.rawValue, ChainDirection.bottomRight.rawValue, 0, 0, 0, 0, 0, 0,

    // 000
    // 0 1
    // 111
    ChainDirection.bottomLeft.rawValue, ChainDirection.right.rawValue, 0, 0, 0, 0, 0, 0,

    // 100
    // 0 1
    // 111
    ChainDirection.bottomLeft.rawValue, ChainDirection.topLeft.rawValue, ChainDirection.topLeft.rawValue, ChainDirection.right.rawValue, 0, 0, 0, 0,

    // 010
    // 0 1
    // 111
    ChainDirection.bottomLeft.rawValue, ChainDirection.up.rawValue, 0, 0, 0, 0, 0, 0,

    // 110
    // 0 1
    // 111
    ChainDirection.bottomLeft.rawValue, ChainDirection.topLeft.rawValue, 0, 0, 0, 0, 0, 0,

    // 001
    // 0 1
    // 111
    ChainDirection.bottomLeft.rawValue, ChainDirection.topRight.rawValue, 0, 0, 0, 0, 0, 0,

    // 101
    // 0 1
    // 111
    ChainDirection.bottomLeft.rawValue, ChainDirection.topLeft.rawValue, ChainDirection.topLeft.rawValue, ChainDirection.topRight.rawValue, 0, 0, 0, 0,

    // 011
    // 0 1
    // 111
    ChainDirection.bottomLeft.rawValue, ChainDirection.up.rawValue, 0, 0, 0, 0, 0, 0,

    // 111
    // 0 1
    // 111
    ChainDirection.bottomLeft.rawValue, ChainDirection.topLeft.rawValue, 0, 0, 0, 0, 0, 0,

    // 000
    // 1 1
    // 111
    ChainDirection.left.rawValue, ChainDirection.right.rawValue, 0, 0, 0, 0, 0, 0,

    // 100
    // 1 1
    // 111
    ChainDirection.topLeft.rawValue, ChainDirection.right.rawValue, 0, 0, 0, 0, 0, 0,

    // 010
    // 1 1
    // 111
    0, 0, 0, 0, 0, 0, 0, 0,

    // 110
    // 1 1
    // 111
    0, 0, 0, 0, 0, 0, 0, 0,

    // 001
    // 1 1
    // 111
    ChainDirection.left.rawValue, ChainDirection.topRight.rawValue, 0, 0, 0, 0, 0, 0,

    // 101
    // 1 1
    // 111
    ChainDirection.topLeft.rawValue, ChainDirection.topRight.rawValue, 0, 0, 0, 0, 0, 0,

    // 011
    // 1 1
    // 111
    0, 0, 0, 0, 0, 0, 0, 0,

    // 111
    // 1 1
    // 111
    0, 0, 0, 0, 0, 0, 0, 0,
]
