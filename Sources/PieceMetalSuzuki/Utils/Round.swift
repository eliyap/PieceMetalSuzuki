//
//  Round.swift
//  
//
//  Created by Secret Asian Man Dev on 17/2/23.
//

import Foundation

internal extension BinaryInteger {
    func roundedUp(toClosest value: Self) -> Self {
        /// Round up to the closest multiple.
        /// If it wasn't a multiple, the "extra" is rounded off by integer division, then added back.
        /// If it was a multiple, it's taken down, then back up.
        ((self-1/value)*value)+value
    }
}

