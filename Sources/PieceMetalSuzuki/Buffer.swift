//
//  Buffer.swift
//  
//
//  Created by Secret Asian Man Dev on 16/2/23.
//

import Metal

public final class Buffer<Element> {
    
    public let count: Int
    public let array: UnsafeMutablePointer<Element>
    public let mtlBuffer: MTLBuffer
    
    init?(device: MTLDevice, count: Int) {
        let size = MemoryLayout<Element>.stride * count
        guard let buffer = device.makeBuffer(length: size) else {
            assert(false, "Failed to create buffer.")
            return nil
        }
        
        self.count = count
        self.mtlBuffer = buffer
        self.array = buffer.contents().bindMemory(to: Element.self, capacity: count)
    }
    
    deinit {
        mtlBuffer.setPurgeableState(.empty)
    }
}
