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
func autoreleasepool(invoking block: () throws -> Void) rethrows {
    try block()
}
#endif


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


    func section(name: String) throws {
        sectionId = nil
        benchmarkId = nil
        benchmarkName = ""
        benchmarkUnits = ""

        print("\n\(name)")
        print(String(repeating: "-", count: name.count), terminator: "\n\n")
        self.sectionId = try benchmarkDb?.addSection(name: name)
    }


    func benchmark(name: String, units: String) throws {
        guard let sectionId = self.sectionId else {
            fatalError("No valid sectionId, check test has a 'try statsLogger.section(name: \"TestName\")' call")
        }

        benchmarkName = name
        benchmarkUnits = units
        self.benchmarkId = try benchmarkDb?.addBenchmark(sectionId: sectionId, name: name, units: units)
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
    ]
}
#endif
