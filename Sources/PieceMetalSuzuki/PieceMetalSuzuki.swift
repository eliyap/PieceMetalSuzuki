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
        guard 
            let metalDevice = MTLCreateSystemDefaultDevice(), 
            let commandQueue = metalDevice.makeCommandQueue(),
            let binaryBuffer = commandQueue.makeCommandBuffer()
        else {
            assert(false, "Failed to get metal device.")
            return
        }
        
        var metalTextureCache: CVMetalTextureCache!
        guard CVMetalTextureCacheCreate(kCFAllocatorDefault, nil, metalDevice, nil, &metalTextureCache) == kCVReturnSuccess else {
            assert(false, "Unable to allocate texture cache")
            return
        }
        
        
        /// This is 1 in both signed and unsigned numbers.
        let setVal: Float = 1.0/256.0
        let binary = MPSImageThresholdBinary(device: metalDevice, thresholdValue: 0.5, maximumValue: setVal, linearGrayColorTransform: nil)
        guard let textureA = makeTextureFromCVPixelBuffer(pixelBuffer: bufferA, textureFormat: .bgra8Unorm, textureCache: metalTextureCache) else {
            assert(false, "Failed to create texture.")
            return
        }
        guard let textureB = makeTextureFromCVPixelBuffer(pixelBuffer: bufferB, textureFormat: .bgra8Unorm, textureCache: metalTextureCache) else {
            assert(false, "Failed to create texture.")
            return
        }
        binary.encode(commandBuffer: binaryBuffer, sourceTexture: textureA, destinationTexture: textureB)
        binaryBuffer.commit()
        
        /// Read values from pixel buffer.
        CVPixelBufferLockBaseAddress(bufferB, [])
        defer {
            CVPixelBufferUnlockBaseAddress(bufferB, [])
        }
        guard let ptr = CVPixelBufferGetBaseAddress(bufferB) else {
            assert(false, "Failed to get base address.")
            return
        }

        /// Run Suzuki algorithm.
        var img = ImageBuffer(ptr: ptr, width: width, height: height)
        border(img: &img)

        /// Write image back out.
        let docUrls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        guard let documentsUrl = docUrls.first else {
            assert(false, "Couldn't get documents directory.")
            return
        }
        let filename = documentsUrl.appendingPathComponent("output.png")

        let outputImage = CIImage(cvPixelBuffer: bufferB)
        let outputContext = CIContext()
        guard let outputData = outputContext.pngRepresentation(of: outputImage, format: .RGBA8, colorSpace: CGColorSpaceCreateDeviceRGB(), options: [:]) else {
            assert(false, "Couldn't get PNG data.")
            return
        }
        do {
            try outputData.write(to: filename)
        } catch {
            assert(false, "Couldn't write file.")
            return
        }
        

        print("so far so good")
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
