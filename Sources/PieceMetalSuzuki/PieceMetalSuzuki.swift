import Foundation
import CoreImage
import CoreVideo
import Metal
import MetalPerformanceShaders

public final class MarkerDetector {
    
    private let device: any MTLDevice
    private let queue: any MTLCommandQueue
    private let textureCache: CVMetalTextureCache
    
    /// The type of Lookup Table used to kickstart contour detection.
    private let patternSize: PatternSize
    
    /// Determines the `Buffer` sizes. Dictated by
    /// - the size of `CVPixelBuffer` we are asked to process.
    /// - size of Lookup Table being used.
    private static let initialTriadCount = 0
    private var triadCount: Int = MarkerDetector.initialTriadCount
    
    /// Retained between calls, due to memory leak issue. See `Buffer`.
    private var pointsFilled: Buffer<PixelPoint>! = nil
    private var runsFilled: Buffer<Run>! = nil
    private var pointsUnfilled: Buffer<PixelPoint>! = nil
    private var runsUnfilled: Buffer<Run>! = nil
    
    public init?(device: any MTLDevice, patternSize: PatternSize) {
        self.device = device
        self.patternSize = patternSize
        
        guard let commandQueue = device.makeCommandQueue() else {
            assert(false, "Failed to get metal queue.")
            return nil
        }
        self.queue = commandQueue
        
        var metalTextureCache: CVMetalTextureCache!
        guard CVMetalTextureCacheCreate(kCFAllocatorDefault, nil, device, nil, &metalTextureCache) == kCVReturnSuccess else {
            assert(false, "Unable to allocate texture cache")
            return nil
        }
        self.textureCache = metalTextureCache
        
        guard loadLookupTables(patternSize) else {
            assertionFailure("Failed to load lookup tables for pattern")
            return nil
        }
    }
    
    public convenience init?(patternSize: PatternSize) {
        guard let device = MTLCreateSystemDefaultDevice() else {
            return nil
        }
        self.init(device: device, patternSize: patternSize)
    }
    
    public func detect(pixelBuffer: CVPixelBuffer) -> Void {
        /// Apply a binary filter to make the image black & white.
        guard let filteredBuffer = Profiler.time(.binarize, {
            applyMetalFilter(to: pixelBuffer, device: device, commandQueue: queue, metalTextureCache: textureCache)
        }) else {
            assert(false, "Failed to create pixel buffer.")
            return
        }
        
        /// Obtain a Metal Texture from the image.
        guard let texture = Profiler.time(.makeTexture, {
            makeTextureFromCVPixelBuffer(pixelBuffer: filteredBuffer, textureFormat: .bgra8Unorm, textureCache: textureCache)
        }) else {
            assert(false, "Failed to create texture.")
            return
        }
        
        let roundedWidth = UInt32(texture.width).roundedUp(toClosest: patternSize.coreSize.width)
        let roundedHeight = UInt32(texture.height).roundedUp(toClosest: patternSize.coreSize.height)
        let count = Int(roundedWidth * roundedHeight * patternSize.pointsPerPixel)
        if count != self.triadCount {
            /// Warn myself about possible memory leak.
            if count != MarkerDetector.initialTriadCount {
                debugPrint("[Warning] triadCount changed. This may cause a Buffer memory leak.")
            }
            self.triadCount = count
            guard self.allocateBuffers(ofSize: count) else {
                assertionFailure("Failed to allocate buffers.")
                return
            }
        }
        
        /// Run core algorithms.
        let runIndices = applyMetalSuzuki_LUT(device: device, commandQueue: queue, texture: texture, pointsFilled: pointsFilled, runsFilled: runsFilled, pointsUnfilled: pointsUnfilled, runsUnfilled: runsUnfilled, patternSize: patternSize)!
        decodeMarkers(pixelBuffer: pixelBuffer, pointBuffer: pointsFilled, runBuffer: runsFilled, runIndices: runIndices)
    }
    
    private func allocateBuffers(ofSize count: Int) -> Bool {
        guard
            let pointsFilled = Buffer<PixelPoint>(device: device, count: count),
            let runsFilled = Buffer<Run>(device: device, count: count),
            let pointsUnfilled = Buffer<PixelPoint>(device: device, count: count),
            let runsUnfilled = Buffer<Run>(device: device, count: count)
        else {
            assert(false, "Failed to create buffers.")
            return false
        }
        
        self.pointsFilled = pointsFilled
        self.runsFilled = runsFilled
        self.pointsUnfilled = pointsUnfilled
        self.runsUnfilled = runsUnfilled
        return true
    }
}

internal struct PieceMetalSuzuki {
    public init(
        imageUrl: URL,
        patternSize: PatternSize,
        _ block: (MTLDevice, MTLCommandQueue, MTLTexture, CVPixelBuffer, Buffer<PixelPoint>, Buffer<Run>, Buffer<PixelPoint>, Buffer<Run>) -> Void
    ) {
        guard
            let device = MTLCreateSystemDefaultDevice(),
            let commandQueue = device.makeCommandQueue()
        else {
            assert(false, "Failed to get metal device.")
            return
        }
        
        guard let ciImage = CIImage(contentsOf: imageUrl) else {
            assert(false, "Couldn't load image.")
            return
        }
        
        /// Make a pixel buffer.
        let width = Int(ciImage.extent.width)
        let height = Int(ciImage.extent.height)
        let format = kCVPixelFormatType_32BGRA
        let options: NSDictionary = [
            kCVPixelBufferCGImageCompatibilityKey: true,
            kCVPixelBufferMetalCompatibilityKey: true,
        ]
        var pixelBuffer: CVPixelBuffer!
        guard CVPixelBufferCreate(kCFAllocatorDefault, width, height, format, options, &pixelBuffer) == kCVReturnSuccess else {
            assert(false, "Failed to create pixel buffer.")
            return
        }

        /// Copy image to pixel buffer.
        let context = CIContext()
        context.render(ciImage, to: pixelBuffer)
        
        var metalTextureCache: CVMetalTextureCache!
        guard CVMetalTextureCacheCreate(kCFAllocatorDefault, nil, device, nil, &metalTextureCache) == kCVReturnSuccess else {
            assert(false, "Unable to allocate texture cache")
            return
        }
        
        Profiler.time(.overall) {
            guard let filteredBuffer = Profiler.time(.binarize, {
                applyMetalFilter(to: pixelBuffer, device: device, commandQueue: commandQueue, metalTextureCache: metalTextureCache)
            }) else {
                assert(false, "Failed to create pixel buffer.")
                return
            }
            
            guard let texture = Profiler.time(.makeTexture, {
                makeTextureFromCVPixelBuffer(pixelBuffer: filteredBuffer, textureFormat: .bgra8Unorm, textureCache: metalTextureCache)
            }) else {
                assert(false, "Failed to create texture.")
                return
            }
            
            let roundedWidth = UInt32(texture.width).roundedUp(toClosest: patternSize.coreSize.width)
            let roundedHeight = UInt32(texture.height).roundedUp(toClosest: patternSize.coreSize.height)
            let count = Int(roundedWidth * roundedHeight * patternSize.pointsPerPixel)
            
            guard
                let pointBuffer = Buffer<PixelPoint>(device: device, count: count),
                let runBuffer = Buffer<Run>(device: device, count: count),
                let pointsUnfilled = Buffer<PixelPoint>(device: device, count: count),
                let runsUnfilled = Buffer<Run>(device: device, count: count)
            else {
                assert(false, "Failed to create buffer.")
                return
            }

            block(device, commandQueue, texture, pixelBuffer, pointBuffer, runBuffer, pointsUnfilled, runsUnfilled)
        }
        
        //        bufferA = filteredBuffer
//
//        /// Read values from pixel buffer.
//        CVPixelBufferLockBaseAddress(bufferA, [])
//        defer {
//            CVPixelBufferUnlockBaseAddress(bufferA, [])
//        }
//        guard let ptr = CVPixelBufferGetBaseAddress(bufferA) else {
//            assert(false, "Failed to get base address.")
//            return
//        }
//
//        /// Run Suzuki algorithm.
//        var img = ImageBuffer(ptr: ptr, width: width, height: height)
//        border(img: &img)
//
//        /// Write image back out.
//        saveBufferToPng(buffer: bufferA, format: .RGBA8)

        print("so far so good")
    }
}

internal func applyMetalFilter(
    to buffer: CVPixelBuffer,
    device: MTLDevice,
    commandQueue: MTLCommandQueue,
    metalTextureCache: CVMetalTextureCache
) -> CVPixelBuffer? {
    var result: CVPixelBuffer!
    
    guard CVPixelBufferCreate(
        kCFAllocatorDefault,
        CVPixelBufferGetWidth(buffer),
        CVPixelBufferGetHeight(buffer),
        CVPixelBufferGetPixelFormatType(buffer),
        NSDictionary(dictionary: [
            kCVPixelBufferCGImageCompatibilityKey: true,
            kCVPixelBufferMetalCompatibilityKey: true,
        ]),
        &result
    ) == kCVReturnSuccess else {
        assert(false, "Failed to create pixel buffer.")
        return nil
    }
    
    /// Apply Metal filter to pixel buffer.
    guard  let binaryBuffer = commandQueue.makeCommandBuffer() else {
        assert(false, "Failed to get metal device.")
        return nil
    }
    
    guard let source = makeTextureFromCVPixelBuffer(pixelBuffer: buffer, textureFormat: .bgra8Unorm, textureCache: metalTextureCache) else {
        assert(false, "Failed to create texture.")
        return nil
    }
    guard let destination = makeTextureFromCVPixelBuffer(pixelBuffer: result, textureFormat: .bgra8Unorm, textureCache: metalTextureCache) else {
        assert(false, "Failed to create texture.")
        return nil
    }
    
    /// Apply a binary threshold.
    /// This is 1 in both signed and unsigned numbers.
    let setVal: Float = 1.0/256.0
    let binary = MPSImageThresholdBinary(device: device, thresholdValue: 0.5, maximumValue: setVal, linearGrayColorTransform: nil)
    binary.encode(commandBuffer: binaryBuffer, sourceTexture: source, destinationTexture: destination)
    binaryBuffer.commit()
    binaryBuffer.waitUntilCompleted()
    
    return result
}

internal func applyMetalSuzuki(
    device: MTLDevice,
    commandQueue: MTLCommandQueue,
    texture: MTLTexture,
    pointsFilled: Buffer<PixelPoint>,
    runsFilled: Buffer<Run>,
    pointsUnfilled: Buffer<PixelPoint>,
    runsUnfilled: Buffer<Run>
) -> Void {
    let patternSize = PatternSize.w1h1
    
    /// Apply Metal filter to pixel buffer.
    guard createChainStarters(device: device, commandQueue: commandQueue, texture: texture, runBuffer: runsFilled, pointBuffer: pointsFilled) else {
        assert(false, "Failed to run chain start kernel.")
        return
    }
    
    var grid = Grid(
        imageSize: PixelSize(width: UInt32(texture.width), height: UInt32(texture.height)),
        regions: Profiler.time(.initRegions) {
            return initializeRegions(runBuffer: runsFilled, texture: texture, patternSize: patternSize)
        },
        patternSize: patternSize
    )
    
    Profiler.time(.combineAll) {
        grid.combineAll(
            device: device,
            pointsFilled: pointsFilled,
            runsFilled: runsFilled,
            pointsUnfilled: pointsUnfilled,
            runsUnfilled: runsUnfilled,
            commandQueue: commandQueue
        )
    }
    
    return
}

/**
 By convention, this loads the final set of runs and points into the "filled" buffers,
 and retuns the array offsets for the run buffer.
 */
internal func applyMetalSuzuki_LUT(
    device: MTLDevice,
    commandQueue: MTLCommandQueue,
    texture: MTLTexture,
    pointsFilled: Buffer<PixelPoint>,
    runsFilled: Buffer<Run>,
    pointsUnfilled: Buffer<PixelPoint>,
    runsUnfilled: Buffer<Run>,
    patternSize: PatternSize
) -> Range<Int>? {
    /// Apply Metal filter to pixel buffer.
    guard matchPatterns(device: device, commandQueue: commandQueue, texture: texture, runBuffer: runsFilled, pointBuffer: pointsFilled, patternSize: patternSize) else {
        assert(false, "Failed to run chain start kernel.")
        return nil
    }
    
    var grid = Grid(
        imageSize: PixelSize(width: UInt32(texture.width), height: UInt32(texture.height)),
        regions: Profiler.time(.initRegions) {
            return initializeRegions_LUT(runBuffer: runsFilled, texture: texture, patternSize: patternSize)
        },
        patternSize: patternSize
    )
    
    Profiler.time(.combineAll) {
        grid.combineAll(
            device: device,
            pointsFilled: pointsFilled,
            runsFilled: runsFilled,
            pointsUnfilled: pointsUnfilled,
            runsUnfilled: runsUnfilled,
            commandQueue: commandQueue
        )
    }
    
    return grid.regions[0][0].runIndices(imageSize: grid.imageSize, gridSize: grid.gridSize)
}

internal func saveBufferToPng(buffer: CVPixelBuffer, format: CIFormat) -> Void {
    let docUrls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
    guard let documentsUrl = docUrls.first else {
        assert(false, "Couldn't get documents directory.")
        return
    }
    let filename = documentsUrl.appendingPathComponent("output.png")

    let image = CIImage(cvPixelBuffer: buffer)
    let context = CIContext()
    guard let outputData = context.pngRepresentation(of: image, format: format, colorSpace: CGColorSpaceCreateDeviceRGB(), options: [:]) else {
        assert(false, "Couldn't get PNG data.")
        return
    }
    do {
        try outputData.write(to: filename)
    } catch {
        assert(false, "Couldn't write file.")
        return
    }
}

internal func loadChainStarterFunction(device: MTLDevice) -> MTLFunction? {
    do {
        guard let libUrl = Bundle.module.url(forResource: "PieceSuzukiKernel", withExtension: "metal", subdirectory: "Metal") else {
            assert(false, "Failed to get library.")
            return nil
        }
        let source = try String(contentsOf: libUrl)
        let library = try device.makeLibrary(source: source, options: nil)
        guard let function = library.makeFunction(name: "startChain") else {
            assert(false, "Failed to get library.")
            return nil
        }
        return function
    } catch {
        debugPrint(error)
        return nil
    }
}

internal func createChainStarters(
    device: MTLDevice,
    commandQueue: MTLCommandQueue,
    texture: MTLTexture,
    runBuffer: Buffer<Run>,
    pointBuffer: Buffer<PixelPoint>
) -> Bool {
    let start = CFAbsoluteTimeGetCurrent()
    
    guard
        let kernelFunction = loadChainStarterFunction(device: device),
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
    cmdEncoder.setBuffer(Run.LUTBuffer!.mtlBuffer, offset: 0, index: 2)
    cmdEncoder.setBuffer(PixelPoint.LUTBuffer!.mtlBuffer, offset: 0, index: 3)

    let (tPerTG, tgPerGrid) = pipelineState.threadgroupParameters(texture: texture)
    cmdEncoder.dispatchThreadgroups(tgPerGrid, threadsPerThreadgroup: tPerTG)
    cmdEncoder.endEncoding()
    cmdBuffer.commit()
    cmdBuffer.waitUntilCompleted()
    
    #if SHOW_GRID_WORK
    debugPrint("[Initial Points]")
    let count = texture.width * texture.height * 4
    for i in 0..<count where runBuffer.array[i].isValid {
        print(runBuffer.array[i], pointBuffer.array[i])
    }
    #endif
    
    let end = CFAbsoluteTimeGetCurrent()
    Profiler.add(end - start, to: .startChains)
    
    return true
}
