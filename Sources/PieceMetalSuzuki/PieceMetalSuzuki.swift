import Foundation
import CoreImage
import CoreVideo

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
        ]
        var buffer: CVPixelBuffer!
        let status = CVPixelBufferCreate(kCFAllocatorDefault, width, height, format, options, &buffer)
        guard status == kCVReturnSuccess else {
            assert(false, "Failed to create pixel buffer.")
            return
        }

        /// Copy image to pixel buffer.
        let context = CIContext()
        context.render(ciImage, to: buffer)

        /// Read values from pixel buffer.
        CVPixelBufferLockBaseAddress(buffer, [])
        defer {
            CVPixelBufferUnlockBaseAddress(buffer, [])
        }
        guard let ptr = CVPixelBufferGetBaseAddress(buffer) else {
            assert(false, "Failed to get base address.")
            return
        }

        /// Run Suzuki algorithm.
        var img = ImageBuffer(ptr: ptr, width: CVPixelBufferGetWidth(buffer), height: CVPixelBufferGetHeight(buffer))
        border(img: &img)

        /// Write image back out.
        let docUrls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        guard let documentsUrl = docUrls.first else {
            assert(false, "Couldn't get documents directory.")
            return
        }
        let filename = documentsUrl.appendingPathComponent("output.png")

        let outputImage = CIImage(cvPixelBuffer: buffer)
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
