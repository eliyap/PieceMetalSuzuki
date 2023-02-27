import XCTest
@testable import PieceMetalSuzuki

final class Deskew: XCTestCase {
    
    func checkUnitCorner(quad: Quadrilateral) throws {
        let m = matrixFor(quadrilateral: quad)
        XCTAssertNotNil(m)
        let matrix = m!
        
        XCTAssertEqual(quad.corner1.transformed(by: matrix), DoublePoint(x: 0, y: 0))
        XCTAssertEqual(quad.corner2.transformed(by: matrix), DoublePoint(x: 0, y: 1))
        XCTAssertEqual(quad.corner3.transformed(by: matrix), DoublePoint(x: 1, y: 1))
        XCTAssertEqual(quad.corner4.transformed(by: matrix), DoublePoint(x: 1, y: 0))
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
            corner1: DoublePoint(x: 100, y: 400),
            corner2: DoublePoint(x: 200, y: 100),
            corner3: DoublePoint(x: 500, y: 200),
            corner4: DoublePoint(x: 400, y: 500)
        )
        try checkUnitCorner(quad: tilted)
    }
}
