import Foundation
import CoreImage
import CoreVideo
import Metal
import MetalPerformanceShaders

public struct PieceMetalSuzuki {
    public init(imageUrl: URL) {
        LookupTableBuilder.shared = .init(PixelSize(width: 2, height: 1))
        
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
        var bufferA: CVPixelBuffer!
        guard CVPixelBufferCreate(kCFAllocatorDefault, width, height, format, options, &bufferA) == kCVReturnSuccess else {
            assert(false, "Failed to create pixel buffer.")
            return
        }

        /// Copy image to pixel buffer.
        let context = CIContext()
        context.render(ciImage, to: bufferA)
        
        guard
            let device = MTLCreateSystemDefaultDevice(),
            let commandQueue = device.makeCommandQueue()
        else {
            assert(false, "Failed to get metal device.")
            return
        }
        
        var metalTextureCache: CVMetalTextureCache!
        guard CVMetalTextureCacheCreate(kCFAllocatorDefault, nil, device, nil, &metalTextureCache) == kCVReturnSuccess else {
            assert(false, "Unable to allocate texture cache")
            return
        }
        
        Profiler.time(.overall) {
            guard let filteredBuffer = Profiler.time(.binarize, {
                applyMetalFilter(to: bufferA, device: device, commandQueue: commandQueue, metalTextureCache: metalTextureCache)
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
            
            var runLUTBuffer: Buffer<Run>?
            var pointLUTBuffer: Buffer<PixelPoint>?
            Profiler.time(.lutCopy, {
                runLUTBuffer = Run.makeLUTBuffer(device: device)
                pointLUTBuffer = PixelPoint.makeLUTBuffer(device: device)
            })
            guard let runLUTBuffer, let pointLUTBuffer else {
                assertionFailure("Failed to create LUT buffer")
                return
            }

            /// Apply Metal filter to pixel buffer.
            applyMetalSuzuki(device: device, commandQueue: commandQueue, texture: texture, runLUTBuffer: runLUTBuffer, pointLUTBuffer: pointLUTBuffer)
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

public func applyMetalFilter(
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

public func applyMetalSuzuki(
    device: MTLDevice,
    commandQueue: MTLCommandQueue,
    texture: MTLTexture,
    runLUTBuffer: Buffer<Run>,
    pointLUTBuffer: Buffer<PixelPoint>
) -> Void {
    /// Apply Metal filter to pixel buffer.
    guard let result = createChainStarters(device: device, commandQueue: commandQueue, texture: texture, runLUTBuffer: runLUTBuffer, pointLUTBuffer: pointLUTBuffer) else {
        assert(false, "Failed to run chain start kernel.")
        return
    }
    let (pointBuffer, runBuffer) = result
    
    var grid = Grid(
        imageSize: PixelSize(width: UInt32(texture.width), height: UInt32(texture.height)),
        gridSize: PixelSize(width: 1, height: 1),
        regions: Profiler.time(.initRegions) {
            return initializeRegions(runBuffer: runBuffer, texture: texture)
        }
    )
    Profiler.time(.combineAll) {
        grid.combineAll(
            device: device,
            pointsHorizontal: pointBuffer,
            runsHorizontal: runBuffer,
            commandQueue: commandQueue
        )
    }
    
    return
}

func saveBufferToPng(buffer: CVPixelBuffer, format: CIFormat) -> Void {
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

public func makeTextureFromCVPixelBuffer(
    pixelBuffer: CVPixelBuffer, 
    textureFormat: MTLPixelFormat,
    textureCache: CVMetalTextureCache
) -> MTLTexture? {
    let width = CVPixelBufferGetWidth(pixelBuffer)
    let height = CVPixelBufferGetHeight(pixelBuffer)
    
    // Create a Metal texture from the image buffer.
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

public final class Buffer<Element> {
    
    public let count: Int
    public let array: UnsafeMutablePointer<Element>
    public let mtlBuffer: MTLBuffer
    
    init?(device: MTLDevice, count: Int) {
        let start = CFAbsoluteTimeGetCurrent()
        
        let size = MemoryLayout<Element>.stride * count
        guard let buffer = device.makeBuffer(length: size) else {
            assert(false, "Failed to create buffer.")
            return nil
        }
        
        self.count = count
        self.mtlBuffer = buffer
        self.array = buffer.contents().bindMemory(to: Element.self, capacity: count)
        
        let end = CFAbsoluteTimeGetCurrent()
        Profiler.add(end - start, to: .bufferInit)
    }
}

func loadChainStarterFunction(device: MTLDevice) -> MTLFunction? {
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

func createChainStarters(
    device: MTLDevice,
    commandQueue: MTLCommandQueue,
    texture: MTLTexture,
    runLUTBuffer: Buffer<Run>,
    pointLUTBuffer: Buffer<PixelPoint>
) -> (Buffer<PixelPoint>, Buffer<Run>)? {
    let start = CFAbsoluteTimeGetCurrent()
    
    guard
        let kernelFunction = loadChainStarterFunction(device: device),
        let pipelineState = try? device.makeComputePipelineState(function: kernelFunction),
        let cmdBuffer = commandQueue.makeCommandBuffer(),
        let cmdEncoder = cmdBuffer.makeComputeCommandEncoder()
    else {
        assert(false, "Failed to setup pipeline.")
        return nil
    }

    cmdEncoder.label = "Custom Kernel Encoder"
    cmdEncoder.setComputePipelineState(pipelineState)
    cmdEncoder.setTexture(texture, index: 0)

    let count = texture.width * texture.height * 4
    guard
        let pointBuffer = Buffer<PixelPoint>(device: device, count: count),
        let runBuffer = Buffer<Run>(device: device, count: count)
    else {
        assert(false, "Failed to create buffer.")
        return nil
    }
    cmdEncoder.setBuffer(pointBuffer.mtlBuffer, offset: 0, index: 0)
    cmdEncoder.setBuffer(runBuffer.mtlBuffer, offset: 0, index: 1)
    cmdEncoder.setBuffer(runLUTBuffer.mtlBuffer, offset: 0, index: 2)
    cmdEncoder.setBuffer(pointLUTBuffer.mtlBuffer, offset: 0, index: 3)

    let (tPerTG, tgPerGrid) = pipelineState.threadgroupParameters(texture: texture)
    cmdEncoder.dispatchThreadgroups(tgPerGrid, threadsPerThreadgroup: tPerTG)
    cmdEncoder.endEncoding()
    cmdBuffer.commit()
    cmdBuffer.waitUntilCompleted()
    
    #if SHOW_GRID_WORK
    debugPrint("[Initial Points]")
    for i in 0..<count where runBuffer.array[i].isValid {
        print(runBuffer.array[i], pointBuffer.array[i])
    }
    #endif
    
    let end = CFAbsoluteTimeGetCurrent()
    Profiler.add(end - start, to: .startChains)
    
    return (pointBuffer, runBuffer)
}

extension MTLComputePipelineState {
    func threadgroupParameters(texture: MTLTexture) -> (threadgroupsPerGrid: MTLSize, threadsPerThreadgroup: MTLSize) {
        let threadHeight = maxTotalThreadsPerThreadgroup / threadExecutionWidth
        return (
            /// Subdivide grid as far as possible.
            MTLSizeMake(threadExecutionWidth, threadHeight, 1),
            /// Via https://developer.apple.com/documentation/metal/mtlcomputecommandencoder/1443138-dispatchthreadgroups
            /// Also seen in https://developer.apple.com/documentation/avfoundation/additional_data_capture/avcamfilter_applying_filters_to_a_capture_stream
            ///
            /// The weird math is a form of rounding up using integer division.
            /// If thread `width` or `height` evenly divides the texture `width` or `height`, that factor is returned.
            /// Otherwise, the value is increased enough to push division to the next number, effectively rounding up.
            MTLSizeMake(
                (texture.width  + threadExecutionWidth - 1) / threadExecutionWidth,
                (texture.height + threadHeight         - 1) / threadHeight,
                1
            )
        )
    }
}
