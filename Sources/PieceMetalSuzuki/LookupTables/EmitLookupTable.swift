//
//  EmitLookupTable.swift
//  
//
//  Created by Secret Asian Man Dev on 18/2/23.
//

import Foundation

@available(iOS 16.0, *)
@available(macOS 13.0, *)
internal func write(to fileName: String, _ block: (FileHandle) -> Void) -> Void {
    let docsURLs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
    let docsURL = docsURLs.first!
    let fileURL = docsURL.appending(component: fileName)
    let manager = FileManager.default
    if manager.fileExists(atPath: fileURL.path()) {
        try! manager.removeItem(at: fileURL)
    }
    manager.createFile(atPath: fileURL.path(), contents: nil)
    
    /// Write to file.
    let fileHandle = FileHandle(forWritingAtPath: fileURL.path())!
    fileHandle.seekToEndOfFile()
    block(fileHandle)
    fileHandle.closeFile()
}

extension LookupTableBuilder {
    @available(iOS 16.0, *)
    @available(macOS 13.0, *)
    func emitProtoBuf() -> Void {
        write(to: "runIndices\(patternSize.patternCode).buf") { fileHandle in
            var buf = ArrayIndices()
            buf.indices = runIndices.map { UInt32($0) }
            let data = try! buf.serializedData()
            fileHandle.write(data)
        }
        
        write(to: "runTable\(patternSize.patternCode).buf") { fileHandle in
            var buf = StartRunSerialArray()
            buf.contents = runTable.flatMap{ runRow in
                return runRow.map { run in
                    var serial = StartRunSerial()
                    serial.head = Int32(run.head)
                    serial.tail = Int32(run.tail)
                    serial.from = UInt32(run.from)
                    serial.to = UInt32(run.to)
                    return serial
                }
            }
            let data = try! buf.serializedData()
            fileHandle.write(data)
        }

        write(to: "pointIndices\(patternSize.patternCode).buf") { fileHandle in
            var buf = ArrayIndices()
            buf.indices = pointIndices.map { UInt32($0) }
            let data = try! buf.serializedData()
            fileHandle.write(data)
        }

        write(to: "pointTable\(patternSize.patternCode).buf") { fileHandle in
            var buf = StartPointSerialArray()
            buf.contents = pointTable.flatMap{ pointRow in
                return pointRow.map { point in
                    var serial = StartPointSerial()
                    serial.x = UInt32(point.x)
                    serial.y = UInt32(point.y)
                    return serial
                }
            }
            let data = try! buf.serializedData()
            fileHandle.write(data)
        }
    }
}

public func loadLookupTablesProtoBuf(_ patternSize: PatternSize) -> Bool {
    /// - Note: the folder is `./LookupTables/ProtocolBuffers` is copied to `./ProtocolBuffers`. The super-directory is not preserved.
    let dir = "ProtocolBuffers"
    let ext = "buf"
    guard
        let pointTableURL = Bundle.module.url(forResource: "pointTable\(patternSize.patternCode)", withExtension: ext, subdirectory: dir),
        let pointIndicesURL = Bundle.module.url(forResource: "pointIndices\(patternSize.patternCode)", withExtension: ext, subdirectory: dir),
        let runTableURL = Bundle.module.url(forResource: "runTable\(patternSize.patternCode)", withExtension: ext, subdirectory: dir),
        let runIndicesURL = Bundle.module.url(forResource: "runIndices\(patternSize.patternCode)", withExtension: ext, subdirectory: dir)
    else {
        return false
    }
    
    do {
        let pointTableData   = try Data(contentsOf: pointTableURL)
        let pointIndicesData = try Data(contentsOf: pointIndicesURL)
        let runTableData     = try Data(contentsOf: runTableURL)
        let runIndicesData   = try Data(contentsOf: runIndicesURL)
        
        StartPoint.lookupTable        = try StartPointSerialArray(serializedData: pointTableData)
            .contents
            .map { serial in
                StartPoint(x: UInt8(serial.x), y: UInt8(serial.y))
            }
        StartPoint.lookupTableIndices = try ArrayIndices(serializedData: pointIndicesData)
            .indices
            .map { LookupTableBuilder.TableIndex($0) }
        StartRun.lookupTable          = try StartRunSerialArray(serializedData: runTableData)
            .contents
            .map { serial in
                StartRun(tail: Int8(serial.tail), head: Int8(serial.head), from: UInt8(serial.from), to: UInt8(serial.to))
            }
        StartRun.lookupTableIndices   = try ArrayIndices(serializedData: runIndicesData)
            .indices
            .map { LookupTableBuilder.TableIndex($0) }
    } catch {
        assertionFailure("\(error)")
        return false
    }
    
    return true
}
