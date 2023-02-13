//
//  Blit.swift
//  
//
//  Created by Secret Asian Man Dev on 12/2/23.
//

import Foundation
import Metal

func blit(
    device: MTLDevice, commandQueue: MTLCommandQueue,
    blitRunIndices: [Int], srcRuns: UnsafeMutablePointer<Run>,
    srcPts: Buffer<PixelPoint>, dstPts: Buffer<PixelPoint>,
    cpu: Bool = true
) -> Bool {
    if cpu {
        cpuBlit(runIndices: blitRunIndices, srcPts: srcPts.array, srcRuns: srcRuns, dstPts: dstPts.array)
        return true
    } else {
        guard let cmdBuffer = commandQueue.makeCommandBuffer() else {
            assert(false, "Failed to create command buffer.")
            return false
        }
        for request in blitRunIndices {
            guard let cmdEncoder = cmdBuffer.makeBlitCommandEncoder() else {
                assert(false, "Failed to create command encoder.")
                return false
            }
            let run = srcRuns[request]
            cmdEncoder.copy(
                from: srcPts.mtlBuffer, sourceOffset: MemoryLayout<PixelPoint>.stride * Int(run.oldTail),
                to: dstPts.mtlBuffer, destinationOffset: MemoryLayout<PixelPoint>.stride * Int(run.newTail),
                size: MemoryLayout<PixelPoint>.stride * Int(run.oldHead - run.oldTail)
            )
            cmdEncoder.endEncoding()
        }
        cmdBuffer.commit()
        
        Profiler.time(.blitWait) {
            cmdBuffer.waitUntilCompleted()
        }
        
        return true
    }
}

/// For each source run, copy its points to the destination.
func cpuBlit<SomeCollection: Collection>(
    runIndices: SomeCollection,
    srcPts: UnsafeMutablePointer<PixelPoint>, srcRuns: UnsafeMutablePointer<Run>,
    dstPts: UnsafeMutablePointer<PixelPoint>
) -> Void where
    SomeCollection.Element == Int,
    SomeCollection.Index == Int
{
    DispatchQueue.concurrentPerform(iterations: runIndices.count) { runIdxIdx in
        let runIdx = runIndices[runIdxIdx]
        #if SHOW_GRID_WORK
        debugPrint("[BLIT] \(run)")
        #endif
        let run = srcRuns[runIdx]
        memmove(
            dstPts.advanced(by: Int(run.newTail)),
            srcPts.advanced(by: Int(run.oldTail)),
            MemoryLayout<PixelPoint>.stride * Int(run.oldHead - run.oldTail)
        )
    }
}
