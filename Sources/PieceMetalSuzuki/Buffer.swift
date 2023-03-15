//  Buffer.swift
//  Created by Secret Asian Man Dev on 16/2/23.

import Metal

/// An typed wrapper around an array which is shared between the CPU and GPU.
internal final class Buffer<Element> {
    
    /// Number of `Element`s in the buffer.
    public let count: Int
    
    /// Size of the buffer in bytes.
    public let size: Int
        
    public let array: UnsafeMutableBufferPointer<Element>
    public let mtlBuffer: MTLBuffer
    
    public init?(device: MTLDevice, count: Int, token: AutoReleasePoolToken) {
        self.size = MemoryLayout<Element>.stride * count
        guard let buffer = device.makeBuffer(length: size, options: [.storageModeShared]) else {
            assert(false, "Failed to create buffer.")
            return nil
        }
        
        self.count = count
        self.mtlBuffer = buffer
        
        /** - Warning: 23.02.16
         If not called within `autoreleasepool`, `.contents()` causes a memory leak, even if
         - no `.bindMemory` is called
         - the return pointer is never assigned to a variable
         - the `MTLBuffer` has no remaining references.
         - `.setPurgeableState(.empty)` is called.
         */
        self.array = UnsafeMutableBufferPointer<Element>(
            start: buffer.contents().bindMemory(to: Element.self, capacity: count),
            count: count
        )
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
