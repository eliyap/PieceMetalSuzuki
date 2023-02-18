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
    func emit() -> Void {
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
    
    static func load(_ patternSize: PatternSize) -> Bool {
        let dir = "JSONLookupTables"
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
}
