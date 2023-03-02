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
    func emitJSON() -> Void {
        let encoder = JSONEncoder()
        let patternCode = "\(patternSize.coreSize.width)x\(patternSize.coreSize.height)"
        write(to: "runIndices\(patternCode).json") { fileHandle in
            let data = try! encoder.encode(runIndices)
            fileHandle.write(data)
        }
        
        write(to: "runTable\(patternCode).json") { fileHandle in
            let table: [StartRun] = runTable.reduce([], +)
            let data = try! encoder.encode(table)
            fileHandle.write(data)
        }
        
        write(to: "pointIndices\(patternCode).json") { fileHandle in
            let data = try! encoder.encode(pointIndices)
            fileHandle.write(data)
        }

        write(to: "pointTable\(patternCode).json") { fileHandle in
            let table: [StartPoint] = pointTable.reduce([], +)
            let data = try! encoder.encode(table)
            fileHandle.write(data)
        }
    }
}

extension LookupTableBuilder {
    @available(iOS 16.0, *)
    @available(macOS 13.0, *)
    func emitProtoBuf() -> Void {
        let patternCode = "\(patternSize.coreSize.width)x\(patternSize.coreSize.height)"
        write(to: "runIndices\(patternCode).buf") { fileHandle in
            var buf = ArrayIndices()
            buf.indices = runIndices.map { UInt32($0) }
            let data = try! buf.serializedData()
            fileHandle.write(data)
        }
        
        write(to: "runTable\(patternCode).buf") { fileHandle in
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

        write(to: "pointIndices\(patternCode).buf") { fileHandle in
            var buf = ArrayIndices()
            buf.indices = pointIndices.map { UInt32($0) }
            let data = try! buf.serializedData()
            fileHandle.write(data)
        }

        write(to: "pointTable\(patternCode).buf") { fileHandle in
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

public func loadLookupTablesJSON(_ patternSize: PatternSize) -> Bool {
    /// - Note: the folder is `./LookupTables/JSON` is copied to `./JSON`. The super-directory is not preserved.
    let dir = "JSON"
    let ext = "json"
    let patternCode = "\(patternSize.coreSize.width)x\(patternSize.coreSize.height)"
    let decoder = JSONDecoder()
    guard
        let pointTableURL = Bundle.module.url(forResource: "pointTable\(patternCode)", withExtension: ext, subdirectory: dir),
        let pointIndicesURL = Bundle.module.url(forResource: "pointIndices\(patternCode)", withExtension: ext, subdirectory: dir),
        let runTableURL = Bundle.module.url(forResource: "runTable\(patternCode)", withExtension: ext, subdirectory: dir),
        let runIndicesURL = Bundle.module.url(forResource: "runIndices\(patternCode)", withExtension: ext, subdirectory: dir)
    else {
        return false
    }
    
    do {
        let pointTableData   = try Data(contentsOf: pointTableURL)
        let pointIndicesData = try Data(contentsOf: pointIndicesURL)
        let runTableData     = try Data(contentsOf: runTableURL)
        let runIndicesData   = try Data(contentsOf: runIndicesURL)
        
        StartPoint.lookupTable        = try decoder.decode([StartPoint].self, from: pointTableData)
        StartPoint.lookupTableIndices = try decoder.decode([UInt16].self, from: pointIndicesData)
        StartRun.lookupTable          = try decoder.decode([StartRun].self, from: runTableData)
        StartRun.lookupTableIndices   = try decoder.decode([UInt16].self, from: runIndicesData)
    } catch {
        assertionFailure("\(error)")
        return false
    }
    
    return true
}
