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
    func withLockedBaseAddress(_ block: (PixelBufferBaseAddressLockToken) throws -> Void) rethrows -> Void {
        /// Necessary before both
        /// - `CVPixelBufferGetBaseAddress`
        /// - `CVPixelBufferGetBaseAddressOfPlane`
        CVPixelBufferLockBaseAddress(self, [])
        try block(PixelBufferBaseAddressLockToken())
        CVPixelBufferUnlockBaseAddress(self, [])
    }
}
