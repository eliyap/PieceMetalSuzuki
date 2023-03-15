//  MTLMatchPattern.swift
//  Created by Secret Asian Man Dev on 16/2/23.

import Metal

/// - Returns: `true` if no error occurred.
internal func matchPatterns(
    device: MTLDevice,
    commandQueue: MTLCommandQueue,
    texture: MTLTexture,
    runBuffer: Buffer<Run>,
    pointBuffer: Buffer<PixelPoint>,
    patternSize: PatternSize
) -> Bool {
    guard
        let kernelFunction = loadMetalFunction(filename: "MatchPattern", functionName: "matchPatterns\(patternSize.patternCode)", device: device),
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

    /// Copy lookup tables to GPU.
    let runTableBuffer = device.makeBuffer(
        bytes: &StartRun.lookupTable,
        length: MemoryLayout<StartRun>.stride * StartRun.lookupTable.count,
        options: []
    )
    cmdEncoder.setBuffer(runTableBuffer, offset: 0, index: 2)

    let runTableIndicesBuffer = device.makeBuffer(
        bytes: &StartRun.lookupTableIndices,
        length: MemoryLayout<LookupTableBuilder.TableIndex>.stride * StartRun.lookupTableIndices.count,
        options: []
    )
    cmdEncoder.setBuffer(runTableIndicesBuffer, offset: 0, index: 3)

    let pointTableBuffer = device.makeBuffer(
        bytes: &StartPoint.lookupTable,
        length: MemoryLayout<StartPoint>.stride * StartPoint.lookupTable.count,
        options: []
    )
    cmdEncoder.setBuffer(pointTableBuffer, offset: 0, index: 4)
    
    let pointTableIndicesBuffer = device.makeBuffer(
        bytes: &StartPoint.lookupTableIndices,
        length: MemoryLayout<LookupTableBuilder.TableIndex>.stride * StartPoint.lookupTableIndices.count,
        options: []
    )
    cmdEncoder.setBuffer(pointTableIndicesBuffer, offset: 0, index: 5)
    
    let (tPerTG, tgPerGrid) = pipelineState.threadgroupParameters(texture: texture)
    cmdEncoder.dispatchThreadgroups(tgPerGrid, threadsPerThreadgroup: tPerTG)
    cmdEncoder.endEncoding()
    cmdBuffer.commit()
    cmdBuffer.waitUntilCompleted()
    
    #if SHOW_GRID_WORK
    debugPrint("[Initial Points]")
    for idx in 0..<runBuffer.count {
        let run = runBuffer.array[idx]
        guard run.isValid else { continue}
        print(idx, run, (run.oldTail..<run.oldHead).map { pointBuffer.array[Int($0)] })
    }
    #endif
    
    return true
}

/// Load and compile the `.metal` code which ships with the package.
internal func loadMetalFunction(filename: String, functionName: String, device: any MTLDevice) -> (any MTLFunction)? {
    guard let library: any MTLLibrary = loadMetalLibrary(named: filename, device: device) else {
        assert(false, "Failed to get library.")
        return nil
    }
    
    guard let function = library.makeFunction(name: functionName) else {
        assert(false, "Failed to make function.")
        return nil
    }
    return function
}

internal func loadMetalLibrary(named name: String, device: any MTLDevice) -> (any MTLLibrary)? {
    do {
        guard let libUrl = Bundle.module.url(forResource: name, withExtension: "metal", subdirectory: "Metal") else {
            assert(false, "Failed to get library.")
            return nil
        }
        let source = try String(contentsOf: libUrl)
        return try device.makeLibrary(source: source, options: nil)
    } catch {
        debugPrint(error)
        return nil
    }
}

/// - Returns: `true` if no error occurred.
internal func combinePatterns(
    device: MTLDevice,
    commandQueue: MTLCommandQueue,
    texture: MTLTexture,
    runBuffer: Buffer<Run>,
    pointBuffer: Buffer<PixelPoint>,
    patternSize: PatternSize,
    token: AutoReleasePoolToken
) -> Bool {
    guard
        let kernelFunction = loadMetalFunction(filename: "MatchPattern", functionName: "combine\(patternSize.patternCode)", device: device),
        let pipelineState = try? device.makeComputePipelineState(function: kernelFunction),
        let cmdBuffer = commandQueue.makeCommandBuffer(),
        let cmdEncoder = cmdBuffer.makeComputeCommandEncoder()
    else {
        assert(false, "Failed to setup pipeline.")
        return false
    }
    
    guard
        let tempPoints = Buffer<PixelPoint>(device: device, count: pointBuffer.count, token: token),
        let tempRuns = Buffer<Run>(device: device, count: runBuffer.count, token: token)
    else {
        assert(false, "Failed to create buffers.")
        return false
    }
    
    cmdEncoder.label = "Custom Kernel Encoder"
    cmdEncoder.setComputePipelineState(pipelineState)
    cmdEncoder.setTexture(texture, index: 0)

    cmdEncoder.setBuffer(pointBuffer.mtlBuffer, offset: 0, index: 0)
    cmdEncoder.setBuffer(runBuffer.mtlBuffer, offset: 0, index: 1)
    cmdEncoder.setBuffer(tempPoints.mtlBuffer, offset: 0, index: 2)
    cmdEncoder.setBuffer(tempRuns.mtlBuffer, offset: 0, index: 3)
    
    let (tPerTG, tgPerGrid) = pipelineState.threadgroupParameters(texture: texture)
    cmdEncoder.dispatchThreadgroups(tgPerGrid, threadsPerThreadgroup: tPerTG)
    cmdEncoder.endEncoding()
    cmdBuffer.commit()
    cmdBuffer.waitUntilCompleted()
    
    memmove(pointBuffer.array.baseAddress, tempPoints.array.baseAddress, tempPoints.size)
    
    #if SHOW_GRID_WORK
    debugPrint("[Combined Points]")
    for idx in 0..<runBuffer.count {
        let run = runBuffer.array[idx]
        guard run.isValid else { continue}
        print(idx, run, (run.oldTail..<run.oldHead).map { pointBuffer.array[Int($0)] })
    }
    #endif
    
    return true
}
