//
//  File.swift
//  
//
//  Created by Secret Asian Man Dev on 16/2/23.
//

import Metal

func matchPatterns(
    device: MTLDevice,
    commandQueue: MTLCommandQueue,
    texture: MTLTexture,
    runBuffer: Buffer<Run>,
    pointBuffer: Buffer<PixelPoint>
) -> Bool {
    guard
        let kernelFunction = loadMatchPatternFunction(device: device),
        let pipelineState = try? device.makeComputePipelineState(function: kernelFunction),
        let cmdBuffer = commandQueue.makeCommandBuffer(),
        let cmdEncoder = cmdBuffer.makeComputeCommandEncoder()
    else {
        assert(false, "Failed to setup pipeline.")
        return false
    }
    
    cmdEncoder.label = "Custom Kernel Encoder"
    cmdEncoder.setComputePipelineState(pipelineState)
    cmdEncoder.setTexture(texture, index: 0)

    cmdEncoder.setBuffer(pointBuffer.mtlBuffer, offset: 0, index: 0)
    cmdEncoder.setBuffer(runBuffer.mtlBuffer, offset: 0, index: 1)

    let runTableBuffer = device.makeBuffer(
        bytes: &StartRun.lookupTable,
        length: MemoryLayout<StartRun>.stride * StartRun.lookupTable.count
    )
    cmdEncoder.setBuffer(runTableBuffer, offset: 0, index: 2)

    let runTableIndicesBuffer = device.makeBuffer(
        bytes: &StartRun.lookupTableIndices,
        length: MemoryLayout<StartRun>.stride * StartRun.lookupTableIndices.count
    )
    cmdEncoder.setBuffer(runTableIndicesBuffer, offset: 0, index: 3)

    let pointTableBuffer = device.makeBuffer(
        bytes: &StartPoint.lookupTable,
        length: MemoryLayout<StartPoint>.stride * StartPoint.lookupTable.count
    )
    cmdEncoder.setBuffer(pointTableBuffer, offset: 0, index: 4)
    
    let pointTableIndicesBuffer = device.makeBuffer(
        bytes: &StartPoint.lookupTableIndices,
        length: MemoryLayout<StartPoint>.stride * StartPoint.lookupTableIndices.count
    )
    cmdEncoder.setBuffer(pointTableIndicesBuffer, offset: 0, index: 5)
    
    let (tPerTG, tgPerGrid) = pipelineState.threadgroupParameters(texture: texture)
    cmdEncoder.dispatchThreadgroups(tgPerGrid, threadsPerThreadgroup: tPerTG)
    cmdEncoder.endEncoding()
    cmdBuffer.commit()
    cmdBuffer.waitUntilCompleted()
    
    return true
}

func loadMatchPatternFunction(device: MTLDevice) -> MTLFunction? {
    do {
        guard let libUrl = Bundle.module.url(forResource: "MatchPattern", withExtension: "metal", subdirectory: "Metal") else {
            assert(false, "Failed to get library.")
            return nil
        }
        let source = try String(contentsOf: libUrl)
        let library = try device.makeLibrary(source: source, options: nil)
        guard let function = library.makeFunction(name: "matchPatterns") else {
            assert(false, "Failed to get library.")
            return nil
        }
        return function
    } catch {
        debugPrint(error)
        return nil
    }
}
