// Copyright 2020 Simon Evans
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

// XCTestManifestss.swift
//
// Created on 11/05/2020
//
// Manages logging of stats to the screen and optionally a DB.
//

import XCTest
import FoundationBenchmarksDB
import Foundation


// autoreleasepool only exists on Darwin so add a dummy for Linux.
#if !_runtime(_ObjC)
public func autoreleasepool<Result>(invoking body: () throws -> Result) rethrows -> Result {
  return try body()
}
#endif

internal func timing(name: String, execute: () throws -> Void) {
    let start = Date()
    do {
        try autoreleasepool {
            try execute()
        }
        let time = Decimal(Int(-start.timeIntervalSinceNow * 1000))
        try statsLogger.benchmark(name: name, units: "ms")
        try statsLogger.addEntry(result: time)
    } catch {
        fatalError("Cant write results to DB: \(error)")
    }
}


// How many runs of a test to perform. When running under `swift test -c release` to just test
// the benchmarks, tests should only use 1 run. When running in the benchmarking mode, return
// nil so that the caller can decide how many runs to perform.
func runsInTestMode() -> Int? {
    return (ProcessInfo.processInfo.environment["BENCHMARKS_MODE"] == nil) ? 1 : nil
}


final class StatsLogger {

    private let benchmarkDb: BenchmarksDB?
    private let toolChainId: Int64?

    private var sectionId: Int64?
    private var benchmarkId: Int64?
    private var benchmarkName: String = ""
    private var benchmarkUnits: String = ""


    init() {
        guard let dbId = Int64(ProcessInfo.processInfo.environment["BENCHMARKS_DBID"] ?? ""),
              let dbfile = ProcessInfo.processInfo.environment["BENCHMARKS_DBFILE"]
        else {
            print("No BENCHMARKS_DBID and BENCHMARKS_DBFILE not found in environment - not logging to DB")
            self.benchmarkDb = nil
            self.toolChainId = nil
            return
        }

        do {
            let benchmarkDb = try BenchmarksDB(file: dbfile)
            guard try benchmarkDb.validateToolChainId(dbId) else {
                fatalError("Cant find ToolChainId: \(dbId) in database")
            }
            self.benchmarkDb = benchmarkDb
            toolChainId = dbId
        } catch {
            fatalError("Cant accress benchmarks DB: \(dbfile)")
        }
    }


    private func section(name: String) throws {
        sectionId = nil
        benchmarkId = nil
        benchmarkName = ""
        benchmarkUnits = ""

        print("\n\(name)")
        print(String(repeating: "-", count: name.count), terminator: "\n\n")

        guard let db = benchmarkDb else { return }
        do {
            self.sectionId = try db.addSection(name: name)
        } catch {
            fatalError("Cant addSection: \(name) \(error)")
        }
    }


    func section(file: String = #file, functionName: String = #function) throws {
        var baseName = file.components(separatedBy: "/").last ?? file
        if baseName.hasSuffix(".swift") {
            baseName.removeLast(6)
        }

        var functionName = functionName
        if let idx = functionName.firstIndex(of: "(") {
            functionName = String(functionName[..<idx])
        }
        if functionName.hasPrefix("test") {
            functionName.removeFirst(4)
            if functionName.hasPrefix("_") {
                functionName.removeFirst(1)
            }
        }

        try section(name: "\(baseName).\(functionName)")
    }


    func benchmark(name: String, units: String, file: StaticString = #file, line: UInt = #line) throws {
        benchmarkName = name
        benchmarkUnits = units

        guard let db = benchmarkDb else { return }
        guard let sectionId = self.sectionId else {
            fatalError("No valid sectionId, check test has a 'try statsLogger.section(name: \"TestName\")' call at \(file):\(line)")
        }
        self.benchmarkId = try db.addBenchmark(sectionId: sectionId, name: name, units: units)
    }


    func addEntry(result: Decimal) throws {
        let padding = String(repeating: " ", count: 50 - benchmarkName.count)
        print("\(benchmarkName)\(padding): \(result) \(benchmarkUnits)")
        try benchmarkDb?.addEntry(toolChainId: toolChainId!, benchmarkId: benchmarkId!, result: result)
    }
}


let statsLogger = StatsLogger()

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(Base64Tests.allTests),
        testCase(DecimalTests.allTests),
        testCase(JSONTests.allTests),
    ]
}
#endif
