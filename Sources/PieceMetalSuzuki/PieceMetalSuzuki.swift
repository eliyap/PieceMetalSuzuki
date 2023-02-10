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
        let metalDevice = MTLCreateSystemDefaultDevice(), 
        let commandQueue = metalDevice.makeCommandQueue(),
        let binaryBuffer = commandQueue.makeCommandBuffer()
    else {
        assert(false, "Failed to get metal device.")
        return outBuffer
    }
    
    var metalTextureCache: CVMetalTextureCache!
    guard CVMetalTextureCacheCreate(kCFAllocatorDefault, nil, metalDevice, nil, &metalTextureCache) == kCVReturnSuccess else {
        assert(false, "Unable to allocate texture cache")
        return outBuffer
    }
    
    guard let textureA = makeTextureFromCVPixelBuffer(pixelBuffer: bufferA, textureFormat: .bgra8Unorm, textureCache: metalTextureCache) else {
        assert(false, "Failed to create texture.")
        return outBuffer
    }
    guard let textureB = makeTextureFromCVPixelBuffer(pixelBuffer: bufferB, textureFormat: .bgra8Unorm, textureCache: metalTextureCache) else {
        assert(false, "Failed to create texture.")
        return outBuffer
    }

    let kernelFunction: MTLFunction
    do {
        guard let libUrl = Bundle.module.url(forResource: "PieceSuzukiKernel", withExtension: "metal", subdirectory: "Metal") else {
            assert(false, "Failed to get library.")
            return outBuffer
        }
        let source = try String(contentsOf: libUrl)
        let library = try metalDevice.makeLibrary(source: source, options: nil)
        guard let function = library.makeFunction(name: "rosyEffect") else {
            assert(false, "Failed to get library.")
            return outBuffer
        }
        kernelFunction = function
    } catch {
        debugPrint(error)
        return outBuffer
    }
    
    
    guard
        let pipelineState = try? metalDevice.makeComputePipelineState(function: kernelFunction),
        let kernelBuffer = commandQueue.makeCommandBuffer(),
        let kernelEncoder = kernelBuffer.makeComputeCommandEncoder()
    else {
        assert(false, "Failed to setup pipeline.")
        return outBuffer
    }
    
    kernelEncoder.label = "Custom Kernel Encoder"
    kernelEncoder.setComputePipelineState(pipelineState)
    kernelEncoder.setTexture(textureA, index: 0)
    kernelEncoder.setTexture(textureB, index: 1)
    
    let (tPerTG, tgPerGrid) = pipelineState.threadgroupParameters(texture: textureA)
    kernelEncoder.dispatchThreadgroups(tgPerGrid, threadsPerThreadgroup: tPerTG)
    kernelEncoder.endEncoding()
    kernelBuffer.commit()
    
    /// Apply a binary threshold.
    /// This is 1 in both signed and unsigned numbers.
//    let setVal: Float = 1.0/256.0
//    let binary = MPSImageThresholdBinary(device: metalDevice, thresholdValue: 0.5, maximumValue: setVal, linearGrayColorTransform: nil)
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
