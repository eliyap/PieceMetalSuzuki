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
        var pxbuffer: CVPixelBuffer!
        let status = CVPixelBufferCreate(kCFAllocatorDefault, width, height, format, options, &pxbuffer)
        guard status == kCVReturnSuccess else {
            assert(false, "Failed to create pixel buffer.")
            return
        }

        /// Copy image to pixel buffer.
        let context = CIContext()
        context.render(ciImage, to: pxbuffer)

        /// Read values from pixel buffer.
        CVPixelBufferLockBaseAddress(pxbuffer, [])
        defer {
            CVPixelBufferUnlockBaseAddress(pxbuffer, [])
        }
        guard let baseAddress = CVPixelBufferGetBaseAddress(pxbuffer) else {
            assert(false, "Failed to get base address.")
            return
        }

        let (row, col) = (75, 575)
        let offset = (row * width + col) * 4


        let b = baseAddress.load(fromByteOffset: offset + 0, as: UInt8.self)
        let g = baseAddress.load(fromByteOffset: offset + 1, as: UInt8.self)
        let r = baseAddress.load(fromByteOffset: offset + 2, as: UInt8.self)
        let a = baseAddress.load(fromByteOffset: offset + 3, as: UInt8.self)
        print("b: \(b), g: \(g), r: \(r), a: \(a)")

        
        print("so far so good")
    }
}
