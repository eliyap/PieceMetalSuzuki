import Foundation
import CoreImage
import CoreVideo
import MetalPerformanceShaders

public struct PieceMetalSuzuki {
    public private(set) var text = "Hello, World!"

    public init() {
        guard
            let imageUrl = Bundle.module.url(forResource: "input", withExtension: ".png"),
            let ciImage = CIImage(contentsOf: imageUrl)
        else {
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
        var bufferB: CVPixelBuffer!
        guard
            CVPixelBufferCreate(kCFAllocatorDefault, width, height, format, options, &bufferA) == kCVReturnSuccess,
            CVPixelBufferCreate(kCFAllocatorDefault, width, height, format, options, &bufferB) == kCVReturnSuccess
        else {
            assert(false, "Failed to create pixel buffer.")
            return
        }

        /// Copy image to pixel buffer.
        let context = CIContext()
        context.render(ciImage, to: bufferA)

        /// Apply Metal filter to pixel buffer.
        let outBuffer = applyMetalFilter(bufferA: bufferA, bufferB: bufferB)
        
        /// Read values from pixel buffer.
        CVPixelBufferLockBaseAddress(outBuffer, [])
        defer {
            CVPixelBufferUnlockBaseAddress(outBuffer, [])
        }
        guard let ptr = CVPixelBufferGetBaseAddress(outBuffer) else {
            assert(false, "Failed to get base address.")
            return
        }

        /// Run Suzuki algorithm.
//        var img = ImageBuffer(ptr: ptr, width: width, height: height)
//        border(img: &img)

        /// Write image back out.
        saveBufferToPng(buffer: outBuffer, format: .RGBA8)

        print("so far so good")
    }
}

func applyMetalFilter(bufferA: CVPixelBuffer, bufferB: CVPixelBuffer) -> CVPixelBuffer {
    let outBuffer = bufferB

    /// Apply Metal filter to pixel buffer.
    guard 
        let device = MTLCreateSystemDefaultDevice(),
        let commandQueue = device.makeCommandQueue(),
        let binaryBuffer = commandQueue.makeCommandBuffer()
    else {
        assert(false, "Failed to get metal device.")
        return outBuffer
    }
    
    var metalTextureCache: CVMetalTextureCache!
    guard CVMetalTextureCacheCreate(kCFAllocatorDefault, nil, device, nil, &metalTextureCache) == kCVReturnSuccess else {
        assert(false, "Unable to allocate texture cache")
        return outBuffer
    }
    
    guard let textureA = makeTextureFromCVPixelBuffer(pixelBuffer: bufferA, textureFormat: .bgra8Unorm, textureCache: metalTextureCache) else {
        assert(false, "Failed to create texture.")
        return outBuffer
    }
    
        assert(false, "Failed to run chain start kernel.")
    guard let result = createChainStarters(device: device, commandQueue: commandQueue, textureA: textureA) else {
        return outBuffer
    }
    let (points, runs) = result
    
    /// Apply a binary threshold.
    /// This is 1 in both signed and unsigned numbers.
//    let setVal: Float = 1.0/256.0
//    let binary = MPSImageThresholdBinary(device: device, thresholdValue: 0.5, maximumValue: setVal, linearGrayColorTransform: nil)
//    binary.encode(commandBuffer: binaryBuffer, sourceTexture: textureA, destinationTexture: textureB)
//    binaryBuffer.commit()
//    binaryBuffer.waitUntilCompleted()
    
    return outBuffer
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

func createAlignedMTLBuffer<T>(of type: T.Type, device: MTLDevice, count: Int) -> (UnsafeMutablePointer<T>, MTLBuffer)? {
    var ptr: UnsafeMutableRawPointer? = nil
    
    let alignment = Int(getpagesize())
    let size = MemoryLayout<T>.stride * count

    /// Turns on all bits above the current one.
    /// e.g.`0x1000 -> 0x0FFF -> 0xF000`
    let sizeMask = ~(alignment - 1)

    /// Round up size to the nearest page.
    let roundedSize = (size + alignment - 1) & sizeMask
    posix_memalign(&ptr, alignment, roundedSize)

    /// Type memory.
    let array = ptr!.bindMemory(to: T.self, capacity: count)
    
    guard let buffer = device.makeBuffer(bytesNoCopy: ptr!, length: roundedSize, options: [.storageModeShared], deallocator: nil) else {
        assert(false, "Failed to create buffer.")
        return nil
    }
    return (array, buffer)
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
    textureA: MTLTexture
) -> (UnsafeMutablePointer<PixelPoint>, UnsafeMutablePointer<Run>)? {
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
        let (pointArr, pointBuffer) = createAlignedMTLBuffer(of: PixelPoint.self, device: device, count: count),
        let (runArr, runBuffer) = createAlignedMTLBuffer(of: Run.self, device: device, count: count)
    else {
        assert(false, "Failed to create buffer.")
        return nil
    }
    let pointArrB = UnsafeMutablePointer<PixelPoint>.allocate(capacity: count)
    let runArrB = UnsafeMutablePointer<Run>.allocate(capacity: count)
    
    cmdEncoder.setBuffer(pointBuffer, offset: 0, index: 0)
    cmdEncoder.setBuffer(runBuffer, offset: 0, index: 1)
    cmdEncoder.setBytes(StarterLUT, length: MemoryLayout<ChainDirection.RawValue>.stride * StarterLUT.count, index: 2)

    let (tPerTG, tgPerGrid) = pipelineState.threadgroupParameters(texture: texture)
    cmdEncoder.dispatchThreadgroups(tgPerGrid, threadsPerThreadgroup: tPerTG)
    cmdEncoder.endEncoding()
    cmdBuffer.commit()
    cmdBuffer.waitUntilCompleted()
    var regions: [[Region]] = []
    for row in 0..<textureA.height {
        let regionRow = [Region](unsafeUninitializedCapacity: textureA.width) { buffer, initializedCount in
            for col in 0..<textureA.width {
                /// Count valid elements in each 1x1 region.
                let bufferBase = (row * textureA.width) + col
                var validCount = UInt32.zero
                for offset in 0..<4 {
                    if runArr[bufferBase + offset].isValid {
                        validCount += 1
                    } else {
                        break
                    }
                }
                buffer[col] = Region(
                    origin: PixelPoint(x: UInt32(col), y: UInt32(row)),
                    size: PixelSize(width: 1, height: 1),
                    gridRow: UInt32(row), gridCol: UInt32(col),
                    runsCount: validCount
                )
            }
            initializedCount = textureA.width
        }
        regions.append(regionRow)
    }
    
    var dxn = ReduceDirection.horizontal
    let imgSize = PixelSize(width: UInt32(texture.width), height: UInt32(texture.height))
    var regionSize = PixelSize(width: 1, height: 1)
    while (regions.count > 1) || (regions[0].count > 1) {
        
        let numRows = regions.count
        let numCols = regions[0].count
        
        switch dxn {
        case .horizontal:
            for rowIdx in 0..<numRows {
                for colIdx in stride(from: 0, to: numCols - 1, by: 2).reversed() {
                    let a = regions[rowIdx][colIdx]
                    let b = regions[rowIdx].remove(at: colIdx + 1)
                    combine(a: a, b: b,
                            srcPts: pointArr, srcRuns: runArr,
                            dstPts: pointArrB, dstRuns: runArrB,
                            imgSize: imgSize, regionSize: regionSize)
                }
            }
            regionSize = PixelSize(width: regionSize.width * 2, height: regionSize.height)
        
        case .vertical:
            for rowIdx in stride(from: 0, to: numRows - 1, by: 2).reversed() {
                for colIdx in 0..<numCols {
                    #warning("TODO: combine vertical")
                    
                }
                /// Remove entire row at once.
                regions.remove(at: rowIdx + 1)
            }
            regionSize = PixelSize(width: regionSize.width, height: regionSize.height * 2)
            
        }
        dxn.flip()
    }
    
    return (pointArr, runArr)
}

enum ReduceDirection {
    case horizontal, vertical
    mutating func flip() {
        switch self {
        case .horizontal: self = .vertical
        case .vertical: self = .horizontal
        }
    }
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
