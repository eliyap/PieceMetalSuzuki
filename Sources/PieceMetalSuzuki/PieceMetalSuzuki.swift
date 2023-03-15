import Foundation
import CoreImage
import CoreVideo
import Metal
import MetalPerformanceShaders

public final class MarkerDetector {
    
    private let device: any MTLDevice
    private let queue: any MTLCommandQueue
    private let textureCache: CVMetalTextureCache
    
    public var rdpParameters: RDPParameters = .starter
    
    /// Linear ratio by which to downscale image.
    /// e.g. a 10x10 image downscaled by 2 is 5x5.
    public var scale: Double = 1.0
    
    /// The type of Lookup Table used to kickstart contour detection.
    private let patternSize: PatternSize
    
    /// Determines the `Buffer` sizes. Dictated by
    /// - the size of `CVPixelBuffer` we are asked to process.
    /// - size of Lookup Table being used.
    private static let initialTriadCount = 0
    private var triadCount: Int = MarkerDetector.initialTriadCount
    
    public weak var delegate: (any MarkerDetectorDelegate)? = nil
    
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
        
        guard loadLookupTablesProtoBuf(patternSize) else {
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
        guard let filteredBuffer = SuzukiProfiler.time(.binarize, {
            applyMetalFilter(to: pixelBuffer, scale: self.scale, device: device, commandQueue: queue, metalTextureCache: textureCache)
        }) else {
            assert(false, "Failed to create pixel buffer.")
            return
        }
        
        /// Obtain a Metal Texture from the image.
        guard let texture = SuzukiProfiler.time(.makeTexture, {
            makeTextureFromCVPixelBuffer(pixelBuffer: filteredBuffer, textureFormat: .bgra8Unorm, textureCache: textureCache)
        }) else {
            assert(false, "Failed to create texture.")
            return
        }
        
        /// Run core algorithms.
        let borders = applyMetalSuzuki_LUT(device: device, commandQueue: queue, texture: texture, patternSize: patternSize)
        guard let borders else {
            assertionFailure("Failed to get image contours")
            return
        }
        let imageSize = CGSize(width: CVPixelBufferGetWidth(pixelBuffer), height: CVPixelBufferGetHeight(pixelBuffer))
        let parallelograms = findParallelograms(borders: borders, parameters: self.rdpParameters, scale: self.scale)
        delegate?.didFind(parallelograms: parallelograms, imageSize: imageSize)
        // DEBUG – Building
        if let found = findDoubleDiamond(parallelograms: parallelograms, parameters: .starter) {
            delegate?.didFind(doubleDiamond: found, imageSize: imageSize)
        }
    }
}

public protocol MarkerDetectorDelegate: AnyObject {
    /// Found a set of square-ish shapes among the contours in the image.
    func didFind(parallelograms: [Parallelogram], imageSize: CGSize) -> Void
    
    /// Found a pair of markers.
    func didFind(doubleDiamond: DoubleDiamond, imageSize: CGSize) -> Void
}

internal struct PieceMetalSuzuki {
    public init(
        imageUrl: URL,
        patternSize: PatternSize,
        format: OSType,
        _ block: (MTLDevice, MTLCommandQueue, MTLTexture, CVPixelBuffer) -> Void
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
        
        SuzukiProfiler.time(.overall) {
            let scale = 1.0
            
            guard let filteredBuffer = SuzukiProfiler.time(.binarize, {
                applyMetalFilter(to: pixelBuffer, scale: scale, device: device, commandQueue: commandQueue, metalTextureCache: metalTextureCache)
            }) else {
                assert(false, "Failed to create pixel buffer.")
                return
            }
            
            guard let texture = SuzukiProfiler.time(.makeTexture, {
                makeTextureFromCVPixelBuffer(pixelBuffer: filteredBuffer, textureFormat: .bgra8Unorm, textureCache: metalTextureCache)
            }) else {
                assert(false, "Failed to create texture.")
                return
            }
            
            block(device, commandQueue, texture, pixelBuffer)
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
    }
}

internal func createBuffer(width: Int, height: Int, format: OSType) -> CVPixelBuffer? {
    var buffer: CVPixelBuffer!
    let attributes: CFDictionary = NSDictionary(dictionary: [
        kCVPixelBufferCGImageCompatibilityKey: true,
        kCVPixelBufferMetalCompatibilityKey: true,
    ])
    
    let status = CVPixelBufferCreate(kCFAllocatorDefault, width, height, format, attributes, &buffer)
    guard status == kCVReturnSuccess else {
        assert(false, "Failed to create pixel buffer.")
        return nil
    }
    
    return buffer
}

internal func applyMetalFilter(
    to buffer: CVPixelBuffer,
    scale: Double,
    device: MTLDevice,
    commandQueue: MTLCommandQueue,
    metalTextureCache: CVMetalTextureCache
) -> CVPixelBuffer? {
    let scaledWidth  = Int((Double(CVPixelBufferGetWidth(buffer))  / scale).rounded(.down))
    let scaledHeight = Int((Double(CVPixelBufferGetHeight(buffer)) / scale).rounded(.down))
    
    guard
        let scaledBuffer    = createBuffer(width: scaledWidth, height: scaledHeight, format: CVPixelBufferGetPixelFormatType(buffer)),
        let binarizedBuffer = createBuffer(width: scaledWidth, height: scaledHeight, format: CVPixelBufferGetPixelFormatType(buffer)),
        let sourceTexture    = makeTextureFromCVPixelBuffer(pixelBuffer: buffer, textureFormat: .bgra8Unorm, textureCache: metalTextureCache),
        let scaledTexture    = makeTextureFromCVPixelBuffer(pixelBuffer: scaledBuffer, textureFormat: .bgra8Unorm, textureCache: metalTextureCache),
        let binarizedTexture = makeTextureFromCVPixelBuffer(pixelBuffer: binarizedBuffer, textureFormat: .bgra8Unorm, textureCache: metalTextureCache)
    else {
        assert(false, "Failed to create textures.")
        return nil
    }
    
    
    /// Apply Metal filter to pixel buffer.
    guard  let commandBuffer = commandQueue.makeCommandBuffer() else {
        assert(false, "Failed to get metal device.")
        return nil
    }
    
    var transform = MPSScaleTransform(scaleX: 1.0 / scale, scaleY: 1.0 / scale, translateX: 0, translateY: 0)
    withUnsafePointer(to: &transform) { transformPtr in
        /// Downscale, then binarize, otherwise image will be grayscale, instead of B&W.
        let scale = MPSImageBilinearScale(device: device)
        scale.scaleTransform = transformPtr
        scale.encode(commandBuffer: commandBuffer, sourceTexture: sourceTexture, destinationTexture: scaledTexture)
        
        /// Apply a binary threshold.
        /// This is 1 in both signed and unsigned numbers.
        let setVal: Float = 1.0/256.0
        let binary = MPSImageThresholdBinary(device: device, thresholdValue: 0.5, maximumValue: setVal, linearGrayColorTransform: nil)
        binary.encode(commandBuffer: commandBuffer, sourceTexture: scaledTexture, destinationTexture: binarizedTexture)
        
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
    }
    
    return binarizedBuffer
}

internal func applyMetalSuzuki(
    device: MTLDevice,
    commandQueue: MTLCommandQueue,
    texture: MTLTexture
) -> Range<Int>? {
    let patternSize = PatternSize.w1h1
    
    guard let kernelFunction = loadMetalFunction(filename: "PieceSuzukiKernel", functionName: "startChain", device: device) else {
        assert(false, "Failed to load function.")
        return nil
    }
    return withAutoRelease { token in
        
        let roundedWidth = UInt32(texture.width).roundedUp(toClosest: patternSize.coreSize.width)
        let roundedHeight = UInt32(texture.height).roundedUp(toClosest: patternSize.coreSize.height)
        let count = Int(roundedWidth * roundedHeight * patternSize.pointsPerPixel)
        
        guard
            let pointsFilled = Buffer<PixelPoint>(device: device, count: count, token: token),
            let runsFilled = Buffer<Run>(device: device, count: count, token: token)
        else {
            assert(false, "Failed to create buffers.")
            return nil
        }
        
        /// Apply Metal filter to pixel buffer.
        guard createChainStarters(device: device, function: kernelFunction, commandQueue: commandQueue, texture: texture, runBuffer: runsFilled, pointBuffer: pointsFilled, releaseToken: token) else {
            assert(false, "Failed to run chain start kernel.")
            return nil
        }
        
        var grid = Grid(
            imageSize: PixelSize(width: UInt32(texture.width), height: UInt32(texture.height)),
            regions: SuzukiProfiler.time(.initRegions) {
                return initializeRegions(runBuffer: runsFilled, texture: texture, patternSize: patternSize)
            },
            patternSize: patternSize
        )
        
        SuzukiProfiler.time(.combineAll) {
            grid.combineAll(
                pointsFilled: pointsFilled.array,
                runsFilled: runsFilled.array
            )
        }
        
        return grid.regions[0][0].runIndices(imageSize: grid.imageSize, gridSize: grid.gridSize)
    }
}

/**
 Retuns the borders found in the binary image.
 Each border is represented as an array of points.
 */
internal func applyMetalSuzuki_LUT(
    device: MTLDevice,
    commandQueue: MTLCommandQueue,
    texture: MTLTexture,
    patternSize: PatternSize
) -> [[PixelPoint]]? {
    
    let roundedWidth = UInt32(texture.width).roundedUp(toClosest: patternSize.coreSize.width)
    let roundedHeight = UInt32(texture.height).roundedUp(toClosest: patternSize.coreSize.height)
    let count = Int(roundedWidth * roundedHeight * patternSize.pointsPerPixel)
    
    return withAutoRelease { token in
        guard
            let pointsFilled = Buffer<PixelPoint>(device: device, count: count, token: token),
            let runsFilled = Buffer<Run>(device: device, count: count, token: token)
        else {
            assert(false, "Failed to create buffers.")
            return nil
        }
        
        /// Apply Metal filter to pixel buffer.
        guard matchPatterns(device: device, commandQueue: commandQueue, texture: texture, runBuffer: runsFilled, pointBuffer: pointsFilled, patternSize: patternSize) else {
            assert(false, "Failed to run chain start kernel.")
            return nil
        }
        
        if patternSize == .w4h2 {
            let result = SuzukiProfiler.time(.combineGPU) {
                combinePatterns(device: device, commandQueue: commandQueue, texture: texture, runBuffer: runsFilled, pointBuffer: pointsFilled, patternSize: patternSize)
            }
            guard result else {
                assert(false, "Failed to run chain start kernel.")
                return nil
            }
        }
                
        var grid = Grid(
            imageSize: PixelSize(width: UInt32(texture.width), height: UInt32(texture.height)),
            regions: SuzukiProfiler.time(.initRegions) {
                return initializeRegions(runBuffer: runsFilled, texture: texture, patternSize: patternSize)
            },
            patternSize: patternSize
        )
        
        SuzukiProfiler.time(.combineAll) {
            grid.combineAll(
                pointsFilled: pointsFilled.array,
                runsFilled: runsFilled.array
            )
        }
        
        /// Export points from buffers.
        let region = grid.regions[0][0]
        let runIndices = region.runIndices(imageSize: grid.imageSize, gridSize: grid.gridSize)
        var result: [[PixelPoint]] = []
        for runIdx in runIndices {
            let run = runsFilled.array[runIdx]
            let pointCount = Int(run.oldHead - run.oldTail)
            
            /// Performance critical code. Drop down to fast, unsafe array allocation.
            let points = [PixelPoint](unsafeUninitializedCapacity: pointCount) { ptr, count in
                memmove(
                    ptr.baseAddress,
                    pointsFilled.array.baseAddress!.advanced(by: Int(run.oldTail)),
                    pointCount * MemoryLayout<PixelPoint>.stride
                )
                count = pointCount
            }
            
            result.append(points)
        }
        return result
    }
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

/// Uses GPU to initialize regions by running the provided `.metal` function.
/// - Returns: `true` if no error occurred.
internal func createChainStarters(
    device: MTLDevice,
    function: MTLFunction,
    commandQueue: MTLCommandQueue,
    texture: MTLTexture,
    runBuffer: Buffer<Run>,
    pointBuffer: Buffer<PixelPoint>,
    /// Calling this function from within an `autoreleasepool` prevents memory-leaks in
    /// - the `MTLCommandBuffer` and `MTLComputeCommandEncoder`
    /// - the allocated Lookup Table buffers
    releaseToken: AutoReleasePoolToken
) -> Bool {
    SuzukiProfiler.time(.startChains) {
        guard
            let pipelineState = try? device.makeComputePipelineState(function: function),
            let cmdBuffer = commandQueue.makeCommandBuffer(),
            let cmdEncoder = cmdBuffer.makeComputeCommandEncoder()
        else {
            assert(false, "Failed to setup pipeline.")
            return false
        }

        cmdEncoder.label = "Custom Kernel Encoder"
        cmdEncoder.setComputePipelineState(pipelineState)
        cmdEncoder.setTexture(texture, index: 0)
        
        guard let runLutBuffer = Buffer<Run>.init(device: device, count: Run.LUT.count, token: releaseToken) else {
            assertionFailure("Failed to create LUT buffer")
            return false
        }
        memcpy(runLutBuffer.array.baseAddress, Run.LUT, MemoryLayout<Run>.stride * Run.LUT.count)

        guard let pointLutBuffer = Buffer<PixelPoint>.init(device: device, count: PixelPoint.LUT.count, token: releaseToken) else {
            assertionFailure("Failed to create LUT buffer")
            return false
        }
        memcpy(pointLutBuffer.array.baseAddress, PixelPoint.LUT, MemoryLayout<PixelPoint>.stride * PixelPoint.LUT.count)

        cmdEncoder.setBuffer(pointBuffer.mtlBuffer, offset: 0, index: 0)
        cmdEncoder.setBuffer(runBuffer.mtlBuffer, offset: 0, index: 1)
        cmdEncoder.setBuffer(runLutBuffer.mtlBuffer, offset: 0, index: 2)
        cmdEncoder.setBuffer(pointLutBuffer.mtlBuffer, offset: 0, index: 3)

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

        return true
    }
}

enum MetalDirection: UInt8 { 
    case closed      = 0 /// Indicates a closed border.
    case up          = 1
    case topRight    = 2
    case right       = 3
    case bottomRight = 4
    case down        = 5
    case bottomLeft  = 6
    case left        = 7
    case topLeft     = 8
}

func adjust(point: PixelPoint, dxn: MetalDirection.RawValue) -> PixelPoint {
    switch dxn {
    case MetalDirection.up.rawValue:
        return PixelPoint(x: point.x + 0, y: point.y - 1)
    case MetalDirection.topRight.rawValue:
        return PixelPoint(x: point.x + 1, y: point.y - 1)
    case MetalDirection.right.rawValue:
        return PixelPoint(x: point.x + 1, y: point.y + 0)
    case MetalDirection.bottomRight.rawValue:
        return PixelPoint(x: point.x + 1, y: point.y + 1)
    case MetalDirection.down.rawValue:
        return PixelPoint(x: point.x + 0, y: point.y + 1)
    case MetalDirection.bottomLeft.rawValue:
        return PixelPoint(x: point.x - 1, y: point.y + 1)
    case MetalDirection.left.rawValue:
        return PixelPoint(x: point.x - 1, y: point.y + 0)
    case MetalDirection.topLeft.rawValue:
        return PixelPoint(x: point.x - 1, y: point.y - 1)  
    default:
        return point
    }
}

func isInverse(a: UInt8, b: UInt8) -> Bool {
    if ((a == 0) || (b == 0)) {
        return false;
    }
    let aInv = (a + 4) > 8
        ? (a - 4)
        : (a + 4)
        ;
    return aInv == b;
}
