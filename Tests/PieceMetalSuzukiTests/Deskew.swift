import XCTest
@testable import PieceMetalSuzuki

final class Deskew: XCTestCase {
    
    func checkUnitCorner(quad: Quadrilateral) throws {
        let m = matrixFor(quadrilateral: quad)
        XCTAssertNotNil(m)
        let matrix = m!
        
        let threshold = 0.0000001
        
        XCTAssertEqual(quad.corner1.transformed(by: matrix).x, 0, accuracy: threshold)
        XCTAssertEqual(quad.corner1.transformed(by: matrix).y, 0, accuracy: threshold)

        XCTAssertEqual(quad.corner2.transformed(by: matrix).x, 0, accuracy: threshold)
        XCTAssertEqual(quad.corner2.transformed(by: matrix).y, 1, accuracy: threshold)

        XCTAssertEqual(quad.corner3.transformed(by: matrix).x, 1, accuracy: threshold)
        XCTAssertEqual(quad.corner3.transformed(by: matrix).y, 1, accuracy: threshold)

        XCTAssertEqual(quad.corner4.transformed(by: matrix).x, 1, accuracy: threshold)
        XCTAssertEqual(quad.corner4.transformed(by: matrix).y, 0, accuracy: threshold)
    }
    
    func testIdentity() throws {
        let identity = Quadrilateral(
            corner1: DoublePoint(x: 0, y: 0),
            corner2: DoublePoint(x: 0, y: 1),
            corner3: DoublePoint(x: 1, y: 1),
            corner4: DoublePoint(x: 1, y: 0)
        )
        try checkUnitCorner(quad: identity)
    }

    func testCounter() throws {
        let counter = Quadrilateral(
            corner1: DoublePoint(x: 0, y: 0),
            corner2: DoublePoint(x: 1, y: 0),
            corner3: DoublePoint(x: 1, y: 1),
            corner4: DoublePoint(x: 0, y: 1)
        )
        try checkUnitCorner(quad: counter)
    }

    func testScaled() throws {
        let scaled = Quadrilateral(
            corner1: DoublePoint(x: 0, y: 0),
            corner2: DoublePoint(x: 0, y: 200),
            corner3: DoublePoint(x: 1, y: 200),
            corner4: DoublePoint(x: 1, y: 0)
        )
        try checkUnitCorner(quad: scaled)
    }

    func testTranslated() throws {
        let translated = Quadrilateral(
            corner1: DoublePoint(x: 1, y: 1),
            corner2: DoublePoint(x: 1, y: 2),
            corner3: DoublePoint(x: 2, y: 2),
            corner4: DoublePoint(x: 2, y: 1)
        )
        try checkUnitCorner(quad: translated)
    }

    func testDiamond() throws {
        let diamond = Quadrilateral(
            corner1: DoublePoint(x: 0, y: +1),
            corner2: DoublePoint(x: +1, y: 0),
            corner3: DoublePoint(x: 0, y: -1),
            corner4: DoublePoint(x: -1, y: 0)
        )
        try checkUnitCorner(quad: diamond)
    }

    func testTilted() throws {
        let tilted = Quadrilateral(
            corner1: DoublePoint(x: 1, y: 4),
            corner2: DoublePoint(x: 2, y: 1),
            corner3: DoublePoint(x: 5, y: 2),
            corner4: DoublePoint(x: 4, y: 5)
        )
        try checkUnitCorner(quad: tilted)
    }
}
