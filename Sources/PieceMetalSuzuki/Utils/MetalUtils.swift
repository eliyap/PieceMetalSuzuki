//  MetalUtils.swift
//  Created by Secret Asian Man Dev on 23/2/23.

import Metal
import CoreVideo

internal func makeTextureFromCVPixelBuffer(
    pixelBuffer: CVPixelBuffer,
    textureFormat: MTLPixelFormat,
    textureCache: CVMetalTextureCache
) -> MTLTexture? {
    let width = CVPixelBufferGetWidth(pixelBuffer)
    let height = CVPixelBufferGetHeight(pixelBuffer)
    
    /// Create a Metal texture from the image buffer.
    var cvTextureOut: CVMetalTexture?
    let status = CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault, textureCache, pixelBuffer, nil, textureFormat, width, height, 0, &cvTextureOut)
    guard status == kCVReturnSuccess else {
        debugPrint("Error at CVMetalTextureCacheCreateTextureFromImage \(status)")
        CVMetalTextureCacheFlush(textureCache, 0)
        return nil
    }
    
    guard let cvTexture = cvTextureOut, let texture = CVMetalTextureGetTexture(cvTexture) else {
        CVMetalTextureCacheFlush(textureCache, 0)
        return nil
    }
    
    return texture
}

extension MTLComputePipelineState {
    func threadgroupParameters(texture: MTLTexture) -> (threadgroupsPerGrid: MTLSize, threadsPerThreadgroup: MTLSize) {
        threadgroupParameters(texture: texture, width: 1, height: 1)
    }
    
    func threadgroupParameters(texture: MTLTexture, coreSize: PixelSize) -> (threadgroupsPerGrid: MTLSize, threadsPerThreadgroup: MTLSize) {
        threadgroupParameters(texture: texture, width: Int(coreSize.width), height: Int(coreSize.height))
    }
    
    func threadgroupParameters(texture: MTLTexture, width: Int, height: Int) -> (threadgroupsPerGrid: MTLSize, threadsPerThreadgroup: MTLSize) {
        let threadHeight = maxTotalThreadsPerThreadgroup / threadExecutionWidth
        return (
            /// Subdivide grid as far as possible.
            /// https://developer.apple.com/documentation/metal/mtlcomputecommandencoder/1443138-dispatchthreadgroups
            MTLSizeMake(threadExecutionWidth, threadHeight, 1),
            MTLSizeMake(
                texture.width
                    .dividedByRoundingUp(divisor: width)
                    .dividedByRoundingUp(divisor: threadExecutionWidth),
                texture.height
                    .dividedByRoundingUp(divisor: height)
                    .dividedByRoundingUp(divisor: threadHeight),
                1
            )
        )
    }
}
