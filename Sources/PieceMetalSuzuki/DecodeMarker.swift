//
//  File.swift
//  
//
//  Created by Secret Asian Man Dev on 19/2/23.
//

import Foundation
import CoreVideo

public func decodeMarkers(
    pixelBuffer: CVPixelBuffer,
    pointBuffer: Buffer<PixelPoint>,
    runBuffer: Buffer<Run>,
    runIndices: Range<Int>,
    rdpParameters: RDPParameters = .starter
) -> Void {
    CVPixelBufferLockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
    let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
    
    for runIdx in runIndices {
        let run = runBuffer.array[runIdx]
        let points = (run.oldTail..<run.oldHead).map { ptIdx in
            let pixelPt = pointBuffer.array[Int(ptIdx)]
            return DoublePoint(pixelPt)
        }
        
        let corners = checkQuadrilateral(polyline: points)
        
        guard let corners else{ continue }
        let (c1, c2, c3, c4) = corners

        print("Run \(runIdx) has \(points.count) points")
        
        let addr = CVPixelBufferGetBaseAddress(pixelBuffer)!
            .assumingMemoryBound(to: UInt8.self)
        (run.oldTail..<run.oldHead).forEach { ptIdx in
            let pixelPt = pointBuffer.array[Int(ptIdx)]
            // Mark pixel.
            let offset = (Int(pixelPt.y) * bytesPerRow) + (Int(pixelPt.x) * 4)
            let pixel = addr.advanced(by: offset)
            pixel[0] = 0
            pixel[1] = 0
            pixel[2] = 255
            pixel[3] = 255
        }
        
        guard let m = matrixFor(c1, c2, c3, c4) else {
            debugPrint("Singular matrix")
            continue
        }
        
        print("c1", c1.transformedBy(m))
        print("c2", c2.transformedBy(m))
        print("c3", c3.transformedBy(m))
        print("c4", c4.transformedBy(m))
    }
    CVPixelBufferUnlockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
    saveBufferToPng(buffer: pixelBuffer, format: .RGBA8)
}
