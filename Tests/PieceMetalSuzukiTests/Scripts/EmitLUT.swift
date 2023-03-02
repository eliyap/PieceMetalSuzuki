import XCTest
@testable import PieceMetalSuzuki

/**
 (ab)using tests to run "script" jobs using internal library functions.
 
 These functions use the 1x1 kernel to simulate the first 1,2, or more steps of the "combining" phase of the algorithm.
 The resulting patterns are "emitted" (written to disk) as files which can later be loaded into the program to skip these steps.
 */
@available(iOS 16.0, *)
@available(macOS 13.0, *)
final class EmitLUT: XCTestCase {
    func testEmitLUT2x1JSON() async throws {
        LookupTableBuilder(patternSize: .w2h1).emitJSON()
    }
    
    func testEmitLUT2x2JSON() async throws {
        LookupTableBuilder(patternSize: .w2h2).emitJSON()
    }
}
