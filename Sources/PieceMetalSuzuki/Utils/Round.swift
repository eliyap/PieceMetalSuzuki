//
//  Round.swift
//  
//
//  Created by Secret Asian Man Dev on 17/2/23.
//

import Foundation

public extension BinaryInteger {
    func roundedUp(toClosest value: Self) -> Self {
        /// Round up to the closest multiple.
        /// If it wasn't a multiple, the "extra" is rounded off by integer division, then added back.
        /// If it was a multiple, it's taken down, then back up.
        (((self-1)/value)*value)+value
    }
    
    func dividedByRoundingUp(divisor: Self) -> Self {
        /// Divide self by divisor, rounding up to the closest integer.
        /// If not an even multiple, this "pushes us over" to the next multiple of divisor.
        /// If already a multiple, this doesn't "push us over".
        (self + divisor - 1) / divisor
    }
}
