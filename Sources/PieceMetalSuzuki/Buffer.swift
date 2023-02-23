//
//  Buffer.swift
//  
//
//  Created by Secret Asian Man Dev on 16/2/23.
//

import Metal

/// An typed wrapper around an array which is shared between the CPU and GPU.
public final class Buffer<Element> {
    
    public let count: Int
    public let array: UnsafeMutablePointer<Element>
    public let mtlBuffer: MTLBuffer
    public let size: Int
    
    public init?(device: MTLDevice, count: Int) {
        self.size = MemoryLayout<Element>.stride * count
        guard let buffer = device.makeBuffer(length: size) else {
            assert(false, "Failed to create buffer.")
            return nil
        }
        
        self.count = count
        self.mtlBuffer = buffer
        
        /** - Warning: 23.02.16
         `.contents()` causes a memory leak, even if
         - no `.bindMemory` is called
         - the return pointer is never assigned to a variable
         - the `MTLBuffer` has no remaining references.
         - `.setPurgeableState(.empty)` is called.
         
         I am treating this as a bug to be worked around.
         */
        self.array = buffer.contents().bindMemory(to: Element.self, capacity: count)
    }
    
    deinit {
        mtlBuffer.setPurgeableState(.empty)
    }
}

internal extension Buffer where Element == PixelPoint {
    subscript(_ run: Run) -> [PixelPoint] {
        return (run.oldTail..<run.oldHead).map { ptIdx in
            return array[Int(ptIdx)]
        }
    }
}
