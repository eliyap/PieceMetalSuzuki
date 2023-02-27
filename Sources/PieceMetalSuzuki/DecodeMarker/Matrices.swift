//  Matrices.swift
//  Created by Secret Asian Man Dev on 22/2/23.

import Foundation

internal struct Matrix: CustomStringConvertible {
    public let values: [[Double]]

    public var description: String {
        values.map { row in
            row.map { String(format: "%.2f", $0) }.joined(separator: ", ")
        }.joined(separator: "\n")
    }


    /// Diagonal is used as denominator, must not be too small, otherwise floating point math is whack.
    public static let minDiagonalSize: Double = 0.0000001
    
    public func determinant() -> Double {
        var rows = self.values

        /// Check that matrix is square.
        for row in rows {
            assert(row.count == rows.count, "Matrix is not square")
        }

        /// Use Gaussian elimination to form an upper triangular matrix.
        for rowIdx in 0..<(rows.count-1) {
            var zeroOut = false
            if abs(rows[rowIdx][rowIdx]) > Matrix.minDiagonalSize {
                zeroOut = true
            } else { 
                /// Find the first non-zero element below the diagonal.
                let nonZeroRowIdx = ((rowIdx+1)..<rows.count).first(where: { lowerIdx in 
                    rows[lowerIdx][rowIdx].isZero == false 
                })  
                if let nonZeroRowIdx { 
                    /// Add that row to the current row to make the diagonal element non-zero.
                    for colIdx in 0..<rows.count {
                        rows[rowIdx][colIdx] += rows[nonZeroRowIdx][colIdx]
                    }
                    zeroOut = true
                } else { 
                    /// No need to zero out elements below this diagonal element.
                }
            } 
            
            /// Zero out the elements below the diagonal.
            if zeroOut { 
                for lowerIdx in (rowIdx+1)..<rows.count {
                    let factor = rows[lowerIdx][rowIdx] / rows[rowIdx][rowIdx]
                    for colIdx in 0..<rows.count {
                        rows[lowerIdx][colIdx] -= factor * rows[rowIdx][colIdx]
                    }
                }
            }
        }
        
        /// The determinant of the upper triangular matrix is the product of the diagonal elements.
        var determinant = 1.0
        for idx in 0..<rows.count {
            determinant *= rows[idx][idx]
        }
        return determinant
    }

    public func replacing(columnNo: Int, with values: [Double]) -> Matrix {
        assert(values.count == self.values.count, "Replacement column must have same number of rows as original matrix")
        assert(columnNo < self.values[0].count, "Column number out of range")
        
        var newValues = self.values
        for rowIdx in 0..<values.count {
            newValues[rowIdx][columnNo] = values[rowIdx]
        }
        return Matrix(values: newValues)
    }
}

struct PerspectiveTransformMatrix: CustomStringConvertible {
    let (a, b, c): (Double, Double, Double)
    let (d, e, f): (Double, Double, Double)
    let (g, h   ): (Double, Double        )
    let i = 1.0

    var description: String {
        let format = "%.2f"
        let sep = ", "
        return [
            [
                String(format: format, a),
                String(format: format, b),
                String(format: format, c),
            
            ].joined(separator: sep),
            [
                String(format: format, d),
                String(format: format, e),
                String(format: format, f),
            
            ].joined(separator: sep),
            [
                String(format: format, g),
                String(format: format, h),
                String(format: format, i),
            ].joined(separator: sep),
        ].joined(separator: "\n")
    }
}

extension DoublePoint { 
    func transformed(by matrix: PerspectiveTransformMatrix) -> DoublePoint {
        /// Via https://en.wikipedia.org/wiki/Transformation_matrix#/media/File:Perspective_transformation_matrix_2D.svg
        let (a, b, c) = (matrix.a, matrix.b, matrix.c)
        let (d, e, f) = (matrix.d, matrix.e, matrix.f)
        let (g, h, i) = (matrix.g, matrix.h, matrix.i)
        return DoublePoint(
            x: ((a * self.x) + (b * self.y) + c) / ((g * self.x) + (h * self.y) + i),
            y: ((d * self.x) + (e * self.y) + f) / ((g * self.x) + (h * self.y) + i)
        )
    }
}

internal func matrixFor(quadrilateral: Quadrilateral) -> PerspectiveTransformMatrix? {
    let corner1 = quadrilateral.corner1
    let corner2 = quadrilateral.corner2
    let corner3 = quadrilateral.corner3
    let corner4 = quadrilateral.corner4
    
    /* Adapted from https://github.com/opencv/opencv/blob/11b020b9f9e111bddd40bffe3b1759aa02d966f0/modules/imgproc/src/imgwarp.cpp#L3001
     * Coefficients are calculated by solving linear system:
     * / x1 y1  1  0  0  0 -x1*u1 -y1*u1 \ /a\ /u1\
     * | x2 y2  1  0  0  0 -x2*u2 -y2*u2 | |b| |u2|
     * | x3 y3  1  0  0  0 -x3*u3 -y3*u3 | |c| |u3|
     * | x4 y4  1  0  0  0 -x4*u4 -y4*u4 |.|d|=|u4|,
     * |  0  0  0 x1 y1  1 -x1*v1 -y1*v1 | |e| |v1|
     * |  0  0  0 x2 y2  1 -x2*v2 -y2*v2 | |f| |v2|
     * |  0  0  0 x3 y3  1 -x3*v3 -y3*v3 | |g| |v3|
     * \  0  0  0 x4 y4  1 -x4*v4 -y3*v4 / \h/ \v4/
     * 
     * Here, (u1, v1) = (0, 0), 
     *       (u2, v2) = (0, 1),
     *       (u3, v3) = (1, 1),
     *       (u4, v4) = (1, 0), moving clockwise.
     */
    let (u1, v1) = (0.0, 0.0)
    let (u2, v2) = (0.0, 1.0)
    let (u3, v3) = (1.0, 1.0)
    let (u4, v4) = (1.0, 0.0)
    let matrix = Matrix(values: [
        [corner1.x, corner1.y, 1, 0, 0, 0, -corner1.x * u1, -corner1.y * u1],
        [corner2.x, corner2.y, 1, 0, 0, 0, -corner2.x * u2, -corner2.y * u2],
        [corner3.x, corner3.y, 1, 0, 0, 0, -corner3.x * u3, -corner3.y * u3],
        [corner4.x, corner4.y, 1, 0, 0, 0, -corner4.x * u4, -corner4.y * u4],
        [0, 0, 0, corner1.x, corner1.y, 1, -corner1.x * v1, -corner1.y * v1],
        [0, 0, 0, corner2.x, corner2.y, 1, -corner2.x * v2, -corner2.y * v2],
        [0, 0, 0, corner3.x, corner3.y, 1, -corner3.x * v3, -corner3.y * v3],
        [0, 0, 0, corner4.x, corner4.y, 1, -corner4.x * v4, -corner4.y * v4],
    ])

    let det = matrix.determinant()
    guard det != 0, det.isNaN == false else {
        debugPrint("Matrix inversion failed, det is \(det)")
        return nil
    }

    /// Apply Cramer's rule: https://en.wikipedia.org/wiki/Cramer%27s_rule
    let vecOut = [u1, u2, u3, u4, v1, v2, v3, v4]
    let a = matrix.replacing(columnNo: 0, with: vecOut).determinant() / det
    let b = matrix.replacing(columnNo: 1, with: vecOut).determinant() / det
    let c = matrix.replacing(columnNo: 2, with: vecOut).determinant() / det
    let d = matrix.replacing(columnNo: 3, with: vecOut).determinant() / det
    let e = matrix.replacing(columnNo: 4, with: vecOut).determinant() / det
    let f = matrix.replacing(columnNo: 5, with: vecOut).determinant() / det
    let g = matrix.replacing(columnNo: 6, with: vecOut).determinant() / det
    let h = matrix.replacing(columnNo: 7, with: vecOut).determinant() / det
    
    return PerspectiveTransformMatrix(
        a: a, b: b, c: c, 
        d: d, e: e, f: f, 
        g: g, h: h
    )
}
