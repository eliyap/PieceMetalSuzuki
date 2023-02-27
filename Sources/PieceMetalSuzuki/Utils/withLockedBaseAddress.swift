//  withLockedBaseAddress.swift
//  Created by Secret Asian Man Dev on 27/2/23.

import CoreVideo

internal struct PixelBufferBaseAddressLockToken {
    /// `fileprivate` designed to dis-allow instantiation elsewhere.
    /// Please use the closure to obtain this token.
    /// Thus, existence of the token guarantees a locked base address.
    fileprivate init() { }
}

extension CVPixelBuffer {
    func withLockedBaseAddress(_ block: (UnsafeMutableRawPointer, PixelBufferBaseAddressLockToken) throws -> Void) rethrows -> Void {
        CVPixelBufferLockBaseAddress(self, [])
        
        /// - Warning: assumes that we want to use `baseAddr`, as opposed to `CVPixelBufferGetBaseAddressOfPlane`.
        ///            May need future revision.
        let addr = CVPixelBufferGetBaseAddress(self)!
        let token = PixelBufferBaseAddressLockToken()
        try block(addr, token)
        
        CVPixelBufferUnlockBaseAddress(self, [])
    }
}
