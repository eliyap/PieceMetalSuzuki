import XCTest
@testable import PieceMetalSuzuki

/**
 (ab)using tests to run "script" jobs using internal library functions.
 
 These functions use the 1x1 kernel to simulate the first 1,2, or more steps of the "combining" phase of the algorithm.
 The resulting patterns are "emitted" (written to disk) as files which can later be loaded into the program to skip these steps.
 */
final class EmitLUT: XCTestCase {
    @available(iOS 16.0, *)
    @available(macOS 13.0, *)
    func testEmitLUT2x1() async throws {
        LookupTableBuilder(patternSize: .w2h1).emit()
    }
    
    @available(iOS 16.0, *)
    @available(macOS 13.0, *)
    func testEmitLUT2x2() async throws {
        LookupTableBuilder(patternSize: .w2h2).emit()
    }
}
