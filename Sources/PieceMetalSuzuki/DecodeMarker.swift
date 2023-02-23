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
    let addr = CVPixelBufferGetBaseAddress(pixelBuffer)!
        .assumingMemoryBound(to: UInt8.self)
    let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
    
    for runIdx in runIndices {
        let run = runBuffer.array[runIdx]
        let points = (run.oldTail..<run.oldHead).map { ptIdx in
            let pixelPt = pointBuffer.array[Int(ptIdx)]
            return DoublePoint(pixelPt)
        }
        
        guard let quad = checkQuadrilateral(polyline: points) else {
            continue
        }
        
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
        
        guard let m = matrixFor(quadrilateral: quad) else {
            debugPrint("Singular matrix")
            continue
        }
        
        print("c1", quad.corner1.transformed(by: m))
        print("c2", quad.corner2.transformed(by: m))
        print("c3", quad.corner3.transformed(by: m))
        print("c4", quad.corner4.transformed(by: m))
        
        let samples = sampleSkewedGrid(
            pixelBuffer: pixelBuffer,
            baseAddress: addr,
            quadrilateral: quad,
            parameters: SkewedSampleParameters(marginSize: 0.1, gridSize: 3)
        )
        guard let samples else {
            debugPrint("Failed to sample regions")
            continue
        }
    }
    CVPixelBufferUnlockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
    saveBufferToPng(buffer: pixelBuffer, format: .RGBA8)
}
