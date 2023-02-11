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
    guard let textureB = makeTextureFromCVPixelBuffer(pixelBuffer: bufferB, textureFormat: .bgra8Unorm, textureCache: metalTextureCache) else {
        assert(false, "Failed to create texture.")
        return outBuffer
    }
    
    guard let result = createChainStarters(device: device, commandQueue: commandQueue, textureA: textureA, textureB: textureB) else {
        assert(false, "Failed to run chain start kernel.")
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
    textureA: MTLTexture,
    textureB: MTLTexture
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
    cmdEncoder.setTexture(textureA, index: 0)
    cmdEncoder.setTexture(textureB, index: 1)

    let count = textureA.width * textureA.height * 4
    guard
        let (pointArr, pointBuffer) = createAlignedMTLBuffer(of: PixelPoint.self, device: device, count: count),
        let (runArr, runBuffer) = createAlignedMTLBuffer(of: Run.self, device: device, count: count)
    else {
        assert(false, "Failed to create buffer.")
        return nil
    }
    
    cmdEncoder.setBuffer(pointBuffer, offset: 0, index: 0)
    cmdEncoder.setBuffer(runBuffer, offset: 0, index: 1)
    cmdEncoder.setBytes(StarterLUT, length: MemoryLayout<ChainDirection.RawValue>.stride * StarterLUT.count, index: 2)

    let (tPerTG, tgPerGrid) = pipelineState.threadgroupParameters(texture: textureA)
    cmdEncoder.dispatchThreadgroups(tgPerGrid, threadsPerThreadgroup: tPerTG)
    cmdEncoder.endEncoding()
    cmdBuffer.commit()
    cmdBuffer.waitUntilCompleted()
    
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

struct ChainFragments {

    enum Direction: UInt8, Equatable {
        case closed = 0 /// Indicates a closed border.
        case up          = 1
        case topRight    = 2
        case right       = 3
        case bottomRight = 4
        case down        = 5
        case bottomLeft  = 6
        case left        = 7
        case topLeft     = 8

        var inverse : Direction {
            switch self {
            case .closed: 
                assert(false, "Cannot invert a closed border.")
                return .closed
            case .up:          return .down
            case .topRight:    return .bottomLeft
            case .right:       return .left
            case .bottomRight: return .topLeft
            case .down:        return .up
            case .bottomLeft:  return .topRight
            case .left:        return .right
            case .topLeft:     return .bottomRight
            }
        }
    }
    
    /// Indexes a contiguous sub-section of the array which represents a chain fragment.
    struct Run {
        /// The indices in `[start, end)` format in the current `links` array.
        var oldHead: Int32
        var oldTail: Int32
        
        /// The indices in `[start, end)` format in the next `links` array.
        var newHead: Int32
        var newTail: Int32

        /// Where the chain fragment should connect from and to.
        /// 0 indicates a closed border.
        /// 1-8 indicate directions from upwards, proceeding clockwise.
        var tailTriadFrom: Direction.RawValue
        var headTriadTo: Direction.RawValue
        
        /// An invalid value used to initialize the process.
        static let initial = Run(oldHead: -1, oldTail: -1, newHead: -1, newTail: -1, tailTriadFrom: Direction.closed.rawValue, headTriadTo: Direction.closed.rawValue)
    }
    
    struct PixelPoint: Equatable {
        /// Corresponds to `thread_position_in_grid` with type `uint2`.
        /// https://developer.apple.com/documentation/metal/mtlattributeformat/uint2
        /// > Two unsigned 32-bit values.
        let x: UInt32
        let y: UInt32

        subscript(_ direction: Direction) -> PixelPoint {
            switch direction {
            case .closed: 
                assert(false, "Cannot index a closed border.")
                return self
            case .up:          return PixelPoint(x: x,     y: y - 1)
            case .topRight:    return PixelPoint(x: x + 1, y: y - 1)
            case .right:       return PixelPoint(x: x + 1, y: y    )
            case .bottomRight: return PixelPoint(x: x + 1, y: y + 1)
            case .down:        return PixelPoint(x: x,     y: y + 1)
            case .bottomLeft:  return PixelPoint(x: x - 1, y: y + 1)
            case .left:        return PixelPoint(x: x - 1, y: y    )
            case .topLeft:     return PixelPoint(x: x - 1, y: y - 1)
            }
        }
        
        /// An invalid point, since the frame should never be analyzed.
        static let zero = PixelPoint(x: .zero, y: .zero)
    }
    
    /// A set of pixel coordinates.
    typealias PointArray = [PixelPoint]
    var points: [PixelPoint]
    
    var runs: [Run]
    
    static var initial = ChainFragments(points: [PixelPoint.zero], runs: .init(repeating: .initial, count: 4))
}

extension ChainFragments.PixelPoint: CustomStringConvertible {
    var description: String { "(\(x), \(y))"}
}
extension ChainFragments.Run: CustomStringConvertible {
    var description: String { "(old: [\(oldHead), \(oldTail)), new: [\(newHead), \(newTail)), \(tailTriadFrom), \(headTriadTo))"}
}

extension ChainFragments { 
    enum Source { case A, B }
    static func combine(a: inout ChainFragments, b: inout ChainFragments) -> [Run] {
        var newRuns: [Run] = []
        var newARuns: [Run] = []
        var newBRuns: [Run] = []
        var nextOffset: Int32 = 0

        func findTailForHead(point: PixelPoint, direction: Direction) -> (Run, Source)? { 
            precondition(direction != .closed)
            
            /// For the given head pointer, describe the corresponding tail pointer.
            let tail: PixelPoint = point[direction]
            let from = direction.inverse.rawValue
            
            if let aIdx = a.runs.firstIndex(where: { run in a.points[Int(run.oldTail-1)] == tail && run.tailTriadFrom == from }) {
                return (a.runs.remove(at: aIdx), .A)
            }
            if let bIdx = b.runs.firstIndex(where: { run in b.points[Int(run.oldTail-1)] == tail && run.tailTriadFrom == from }) {
                return (b.runs.remove(at: bIdx), .B)
            }
            return nil
        }

        func findHeadForTail(point: PixelPoint, direction: Direction) -> (Run, Source)? { 
            precondition(direction != .closed)
            
            /// For the given tail pointer, describe the corresponding head pointer.
            let head: PixelPoint = point[direction]
            let to = direction.inverse.rawValue
            
            if let aIdx = a.runs.firstIndex(where: { run in a.points[Int(run.oldHead)] == head && run.headTriadTo == to }) {
                return (a.runs.remove(at: aIdx), .A)
            }
            if let bIdx = b.runs.firstIndex(where: { run in b.points[Int(run.oldHead)] == head && run.headTriadTo == to }) {
                return (b.runs.remove(at: bIdx), .B)
            }
            return nil
        }

        func join(run: Run, source: Source) -> Void {
            var joinedRuns: [(Run, Source)] = [(run, source)]
            
            var headPt = a.points[Int(run.oldHead)]
            var headDxn = Direction(rawValue: run.headTriadTo)!
            while
                headDxn != Direction.closed, /// Skip search if run is closed.
                let (nextRun, src) = findTailForHead(point: headPt, direction: headDxn)
            {
                joinedRuns.append((nextRun, src))
                headPt = a.points[Int(nextRun.oldHead)]
                headDxn = Direction(rawValue: nextRun.headTriadTo)!
            }

            var tailPt = a.points[Int(run.oldTail-1)]
            var tailDxn = Direction(rawValue: run.tailTriadFrom)!
            while
                tailDxn != Direction.closed, /// Skip search if run is closed.
                let (prevRun, src) = findHeadForTail(point: tailPt, direction: tailDxn)
            {
                joinedRuns.insert((prevRun, src), at: 0)
                tailPt = a.points[Int(prevRun.oldTail-1)]
                tailDxn = Direction(rawValue: prevRun.tailTriadFrom)!
            }

            /// At this point, we have an array of connected runs.
            for (oldRun, src) in joinedRuns {
                var modifiedRun = oldRun
                
                /// First, assign each run its new array position.
                let length = oldRun.oldTail - oldRun.oldHead
                modifiedRun.newHead = nextOffset
                modifiedRun.newTail = nextOffset + length
                nextOffset += length
                
                switch src {
                    case .A: newARuns.append(modifiedRun)
                    case .B: newBRuns.append(modifiedRun)
                }
            }

            /// Finally, add the new run to the new runs array.
            newRuns.append(Run(
                oldHead: joinedRuns.last!.0.newHead,
                oldTail: joinedRuns.first!.0.newTail,
                newHead: joinedRuns.last!.0.newHead,  /// This value is not used.
                newTail: joinedRuns.first!.0.newTail, /// This value is not used.
                tailTriadFrom: joinedRuns.first!.0.tailTriadFrom,
                headTriadTo:   joinedRuns.last!.0.headTriadTo
            ))
        }

        while a.runs.isEmpty == false {
            join(run: a.runs.removeLast(), source: .A)
        }
        while b.runs.isEmpty == false {
            join(run: b.runs.removeLast(), source: .B)
        }

        a.runs = newARuns
        b.runs = newBRuns
        return newRuns
    }
}
