//  ByteConvertible.swift
//  Created by Secret Asian Man Dev on 4/3/23.

import Foundation

internal protocol ByteConvertible {
    static var byteCount: Int { get }
    var data: Data { get }
    init(data: Data)
}

extension UInt32: ByteConvertible {
    static var byteCount: Int = 4
    var data: Data {
        Data([
            UInt8(truncatingIfNeeded: self >> 24),
            UInt8(truncatingIfNeeded: self >> 16),
            UInt8(truncatingIfNeeded: self >>  8),
            UInt8(truncatingIfNeeded: self >>  0),
        ])
    }
    init(data: Data) {
        self = UInt32(data[data.indices.lowerBound + 0]) << 24
             | UInt32(data[data.indices.lowerBound + 1]) << 16
             | UInt32(data[data.indices.lowerBound + 2]) <<  8
             | UInt32(data[data.indices.lowerBound + 3]) <<  0
    }
}

extension Array where Element: ByteConvertible {
    var data: Data {
        return self.reduce(Data()) { partialResult, element in
            partialResult + element.data
        }
    }
    
    init(data: Data) {
        let count = data.count / Element.byteCount
        self.init(unsafeUninitializedCapacity: count) { ptr, initCount in
            for offset in stride(from: 0, to: data.count, by: Element.byteCount) {
                ptr[offset / Element.byteCount] = Element(data: data[offset..<(offset+Element.byteCount)])
            }
            initCount = count
        }
    }
}
