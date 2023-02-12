import Foundation
import CoreImage
import CoreVideo
import MetalPerformanceShaders

public class Profiler {
    enum CodeRegion: CaseIterable { 
        case blit, combine, trailingCopy, binarize
    }

    static var timing: [CodeRegion: (Int, TimeInterval)] = {
        var dict = [CodeRegion: (Int, TimeInterval)]()
        for region in CodeRegion.allCases {
            dict[region] = (0, 0)
        }
        return dict
    }()

    init() { }

    static func add(_ duration: TimeInterval, to region: CodeRegion) {
        let (count, total) = Profiler.timing[region]!
        Profiler.timing[region] = (count + 1, total + duration)
    }

    static func time(_ region: CodeRegion, _ block: () -> Void) {
        let start = CFAbsoluteTimeGetCurrent()
        block()
        let end = CFAbsoluteTimeGetCurrent()
        Profiler.add(end - start, to: region)
    }

    static func report() {
        for (region, results) in Profiler.timing where results.0 > 0 {
            let (count, time) = results
            print("\(region): \(time)s, \(count) (avg \(time / Double(count))s)")
        }
    }
}

public struct PieceMetalSuzuki {
    public init(imageUrl: URL) {
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
        
        let start = CFAbsoluteTimeGetCurrent()
        guard let filteredBuffer = applyMetalFilter(to: bufferA) else {
            assert(false, "Failed to create pixel buffer.")
            return
        }
        let end = CFAbsoluteTimeGetCurrent()
        Profiler.add(end - start, to: .binarize)
        

        /// Apply Metal filter to pixel buffer.
        applyMetalSuzuki(pixelBuffer: filteredBuffer)

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

func applyMetalFilter(to buffer: CVPixelBuffer) -> CVPixelBuffer? {
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
    guard 
        let device = MTLCreateSystemDefaultDevice(),
        let commandQueue = device.makeCommandQueue(),
        let binaryBuffer = commandQueue.makeCommandBuffer()
    else {
        assert(false, "Failed to get metal device.")
        return nil
    }
    
    var metalTextureCache: CVMetalTextureCache!
    guard CVMetalTextureCacheCreate(kCFAllocatorDefault, nil, device, nil, &metalTextureCache) == kCVReturnSuccess else {
        assert(false, "Unable to allocate texture cache")
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

func applyMetalSuzuki(pixelBuffer: CVPixelBuffer) -> Void {
    /// Apply Metal filter to pixel buffer.
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
    
    guard let texture = makeTextureFromCVPixelBuffer(pixelBuffer: pixelBuffer, textureFormat: .bgra8Unorm, textureCache: metalTextureCache) else {
        assert(false, "Failed to create texture.")
        return
    }
    guard let result = createChainStarters(device: device, commandQueue: commandQueue, texture: texture) else {
        assert(false, "Failed to run chain start kernel.")
        return
    }
    let (pointBuffer, runBuffer) = result
    
    var grid = Grid(
        imageSize: PixelSize(width: UInt32(texture.width), height: UInt32(texture.height)),
        gridSize: PixelSize(width: 1, height: 1),
        regions: initializeRegions(runBuffer: runBuffer, texture: texture)
    )
    grid.combineAll(
        device: device,
        pointsHorizontal: pointBuffer,
        runsHorizontal: runBuffer,
        commandQueue: commandQueue
    )
    
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

func makeTextureFromCVPixelBuffer(
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

final class Buffer<Element> {
    private let ptr: UnsafeMutableRawPointer
    public let count: Int
    public let array: UnsafeMutablePointer<Element>
    public let mtlBuffer: MTLBuffer
    init?(device: MTLDevice, count: Int) {
        var ptr: UnsafeMutableRawPointer? = nil
    
        let alignment = Int(getpagesize())
        let size = MemoryLayout<Element>.stride * count

        /// Turns on all bits above the current one.
        /// e.g.`0x1000 -> 0x0FFF -> 0xF000`
        let sizeMask = ~(alignment - 1)

        /// Round up size to the nearest page.
        let roundedSize = (size + alignment - 1) & sizeMask
        posix_memalign(&ptr, alignment, roundedSize)

        /// Type memory.
        let array = ptr!.bindMemory(to: Element.self, capacity: count)
        
        guard let buffer = device.makeBuffer(bytesNoCopy: ptr!, length: roundedSize, options: [.storageModeShared], deallocator: nil) else {
            assert(false, "Failed to create buffer.")
            return nil
        }
        
        self.ptr = ptr!
        self.count = count
        self.array = array
        self.mtlBuffer = buffer
    }
    
    deinit {
        ptr.deallocate()
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
    texture: MTLTexture
) -> (Buffer<PixelPoint>, Buffer<Run>)? {
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
    cmdEncoder.setBytes(StarterLUT, length: MemoryLayout<ChainDirection.RawValue>.stride * StarterLUT.count, index: 2)

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
