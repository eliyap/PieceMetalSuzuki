//
//  File.swift
//  
//
//  Created by Secret Asian Man Dev on 19/2/23.
//

import Foundation
import CoreVideo

internal func decodeMarkers(
    pixelBuffer: CVPixelBuffer,
    pointBuffer: Buffer<PixelPoint>,
    runBuffer: Buffer<Run>,
    runIndices: Range<Int>,
    rdpParameters: RDPParameters = .starter
) -> Void {
    pixelBuffer.withLockedBaseAddress { token in
        var candidateQuads = 0
        
        for runIdx in runIndices {
            let run = runBuffer.array[runIdx]
            let points = (run.oldTail..<run.oldHead).map { ptIdx in
                let pixelPt = pointBuffer.array[Int(ptIdx)]
                return DoublePoint(pixelPt)
            }
            
            guard let quad = checkQuadrilateral(polyline: points) else {
                continue
            }
            candidateQuads += 1
            
            let samples = sampleSkewedGrid(
                pixelBuffer: pixelBuffer,
                token: token,
                quadrilateral: quad,
                parameters: SkewedSampleParameters(marginSize: 0.1, gridSize: 3)
            )
            guard let samples else {
                debugPrint("Failed to sample regions")
                continue
            }
        }
        
        debugPrint("\(candidateQuads) candidate quadrilaterals.")
    }
}
