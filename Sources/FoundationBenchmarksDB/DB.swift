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

// DB.swift
//
// Created on 12/05/2020
//
// SQLite interface.
//

import SQLite
import Foundation

public struct ToolChain {
    public let dbid: Int64
    public let name: String
    public let executableURL: URL?


    public init(dbid: Int64, name: String, executableURL: URL? = nil) {
        self.dbid = dbid
        self.name = name
        self.executableURL = executableURL
    }

    // The name to use for the --build-path argument
    public var buildDirectoryName: String {
        var directory = name
        directory = directory.replacingOccurrences(of: " ", with: "_")
        return directory
    }
}


public struct Section {
    public let dbid: Int64
    public let name: String
    public let benchmarks: [Benchmark]

    public init(dbid: Int64, name: String, benchmarks: [Benchmark]) {
        self.dbid = dbid
        self.name = name
        self.benchmarks = benchmarks
    }
}


public struct Benchmark {
    public let dbid: Int64
    public let name: String
    public let units: String
    public let sectionName: String

    public init(dbid: Int64, name: String, units: String, sectionName: String) {
        self.dbid = dbid
        self.name = name
        self.units = units
        self.sectionName = sectionName
    }
}


public struct ToolChainResults {
    public let toolChain: ToolChain
    public let results: [Int64: String]
    public let maxResultWidth: Int
    public let pctResults: [Int64: Int]?
    public let maxPctResultWidth: Int


    public init(toolChain: ToolChain, benchmarks: [Benchmark], results: [Int64: String],
                pctResults: [Int64: Int]? = nil) {
        self.toolChain = toolChain
        self.results = results
        self.pctResults = pctResults

        var maxWidth = toolChain.name.count
        for benchmark in benchmarks {
            if let value = results[benchmark.dbid] {
                let width = value.count + 1 + benchmark.units.count
                maxWidth = max(maxWidth, width)
            }
        }
        maxResultWidth = maxWidth

        var maxPctWidth = 0
        if let pctResults = pctResults {
            for benchmark in benchmarks {
                if let value = pctResults[benchmark.dbid] {
                    let width = value.description.count + 1 + (value > 0 ? 1 : 0)
                    maxPctWidth = max(maxPctWidth, width)
                }
            }
        }
        maxPctResultWidth = maxPctWidth
    }

    public var isDifferenceResults: Bool { pctResults != nil }

    public func pctResultFor(benchmarkId: Int64) -> String {
        if let results = pctResults, let value = results[benchmarkId] {
            return (value > 1 ? "+" : "") + "\(value)%"
        } else {
            return ""
        }
    }
}


public final class BenchmarksDB {

    static public let defaultFilename = "benchmarks.sqlite3"

    private let connection: Connection

    let toolChains = Table("toolchains")
    let toolChainId = Expression<Int64>("tlch_id")
    let toolChainName = Expression<String>("tlch_name")

    let sections = Table("sections")
    let sectionId = Expression<Int64>("sect_id")
    let sectionName = Expression<String>("sect_name")

    let benchmarks = Table("benchmarks")
    let benchmarkId = Expression<Int64>("bnch_id")
    let benchmarkSectionId = Expression<Int64>("bnch_sect_id")
    let benchmarkName = Expression<String>("bnch_name")
    let benchmarkUnits = Expression<String>("bnch_units")

    let entries = Table("entries")
    let entryId = Expression<Int64>("entr_id")
    let entryToolChainId = Expression<Int64>("entr_tlch_id")
    let entryBenchmarkId = Expression<Int64>("entr_bnch_id")
    let entryResult = Expression<String>("entr_result")


    public init(file: String) throws {
        connection = try Connection(file)
    }


    public func createTables() throws {

        _ = try connection.run(toolChains.create(ifNotExists: true) { table in
                table.column(toolChainId, primaryKey: true)
                table.column(toolChainName, unique: true)
            })

        _ = try connection.run(sections.create(ifNotExists: true) { table in
                table.column(sectionId, primaryKey: true)
                table.column(sectionName, unique: true)
            })

        _ = try connection.run(benchmarks.create(ifNotExists: true) { table in
                table.column(benchmarkId, primaryKey: true)
                table.column(benchmarkSectionId, references: sections, sectionId)
                table.column(benchmarkName)
                table.column(benchmarkUnits)
                table.unique(benchmarkSectionId, benchmarkName)
            })

        _ = try connection.run(entries.create(ifNotExists: true) { table in
                table.column(entryId, primaryKey: true)
                table.column(entryToolChainId, references: toolChains, toolChainId)
                table.column(entryBenchmarkId, references: benchmarks, benchmarkId)
                table.column(entryResult)
            })
    }


    public func validateToolChainId(_ dbId: Int64) throws -> Bool {
        if let row = try connection.pluck(toolChains.filter(toolChainId == dbId)) {
            return row[toolChainId] == dbId
        }
        return false
    }


    @discardableResult
    public func addToolChain(name: String) throws -> Int64 {

        if let row = try connection.pluck(toolChains.filter(toolChainName == name)) {
            return row[toolChainId]
        }

        let stmt = try connection.prepare("INSERT INTO toolchains (tlch_name) VALUES (?)")
        try stmt.run(name)
        return connection.lastInsertRowid
    }


    @discardableResult
    public func addSection(name: String) throws -> Int64 {

        if let row = try connection.pluck(sections.filter(sectionName == name)) {
            return row[sectionId]
        }

        let stmt = try connection.prepare("INSERT INTO sections (sect_name) VALUES (?)")
        try stmt.run(name)
        return connection.lastInsertRowid
    }


    @discardableResult
    public func addBenchmark(sectionId sid: Int64, name: String, units: String) throws -> Int64 {

        if let row = try connection.pluck(benchmarks.filter(benchmarkSectionId == sid)
            .filter(benchmarkName == name)) {
            return row[benchmarkId]
        }


        let stmt = try connection.prepare(
"""
INSERT INTO benchmarks (bnch_sect_id, bnch_name, bnch_units)
     VALUES (?, ?, ?)
""")
        try stmt.run(sid, name, units)
        return connection.lastInsertRowid
    }


    @discardableResult
    public func addEntry(toolChainId: Int64, benchmarkId: Int64, result: Decimal) throws -> Int64 {
        let stmt = try connection.prepare(
"""
INSERT INTO entries (entr_tlch_id, entr_bnch_id, entr_result)
     VALUES (?, ?, ?)
""")
        try stmt.run(toolChainId, benchmarkId, result.description)
        return connection.lastInsertRowid
    }


    public func benchmarkEntry(toolChainId: Int64, benchmarkId: Int64) throws -> Decimal? {
        let benchmarkEntryQuery = try connection.prepare(entries.filter(entryToolChainId == toolChainId)
            .filter(entryBenchmarkId == benchmarkId))
        for row in benchmarkEntryQuery {
            if let value = Int64(row[entryResult]) { return Decimal(value) }
        }
        return nil
    }


    public func listBenchmarks() throws -> [Benchmark] {
        let stmt = try connection.prepare(
"""
  SELECT bnch_id, sect_name, bnch_name, bnch_units
    FROM benchmarks
    JOIN sections ON sect_id = bnch_sect_id
ORDER BY sect_id, bnch_name
""")
        try stmt.run()

        var benchmarks: [Benchmark] = []
        for row in stmt {
            var dbId: Int64?
            var section: String?
            var name: String?
            var units: String?

            for (index, columnName) in stmt.columnNames.enumerated() {
                let value = row[index]
                switch columnName {
                case "bnch_id" where value is Int64: dbId = value as? Int64
                case "sect_name" where value is String: section = value as? String
                case "bnch_name" where value is String: name = value as? String
                case "bnch_units" where value is String: units = value as? String
                default: fatalError("Invalid row/value: \(columnName), \(String(describing: value))")
                }
            }
            if let section = section, let dbId = dbId, let name = name, let units = units {
                benchmarks.append(Benchmark(dbid: dbId, name: name, units: units, sectionName: section))
            } else {
                fatalError("Bad DB result from select")
            }
        }
        return benchmarks
    }


    public func fullResultsFor(toolChain: ToolChain, with benchmarks: [Benchmark]) throws -> ToolChainResults {

        let benchmarkIds: Set<Int64> = Set(benchmarks.map { $0.dbid })
        let stmt = try connection.prepare(
"""
   SELECT bnch_id, entr_result
    FROM sections
    JOIN benchmarks ON bnch_sect_id = sect_id
    LEFT OUTER JOIN entries ON entr_bnch_id = bnch_id AND entr_tlch_id = ?
ORDER BY sect_id, bnch_id;
""")
        try stmt.run(toolChain.dbid)

        var results: [Int64: String] = [:]
        for row in stmt {
            var benchmarkId: Int64?
            var entry: String?

            for (index, columnName) in stmt.columnNames.enumerated() {
                let value = row[index]
                switch columnName {
                case "bnch_id" where value is Int64: benchmarkId = value as? Int64
                case "entr_result": entry = value as? String
                default: fatalError("Invalid row/value: \(columnName), \(String(describing: value))")
                }
            }

            if let benchmarkId = benchmarkId, benchmarkIds.contains(benchmarkId), let entry = entry {
                results[benchmarkId] = entry
            }
        }
        return ToolChainResults(toolChain: toolChain, benchmarks: benchmarks, results: results)
    }


    public func resultsFor(toolChains: [ToolChain], with benchmarks: [Benchmark]) throws -> [ToolChainResults] {
        try toolChains.map {
            try fullResultsFor(toolChain: $0, with: benchmarks)
        }
    }


    public func toolChain(byName name: String) throws -> ToolChain? {
        for row in try connection.prepare(toolChains.filter(toolChainName == name)) {
            return ToolChain(dbid: row[toolChainId], name: row[toolChainName])
        }
        return nil
    }


    public func renameToolChain(_ toolChain: ToolChain, to newName: String) throws {
        let stmt = try connection.prepare("UPDATE toolchains SET tlch_name = ? WHERE tlch_id = ?")
        try stmt.run(newName, toolChain.dbid)
    }


    public func deleteToolChain(_ toolChain: ToolChain) throws {
        let stmt = try connection.prepare("DELETE FROM entries WHERE entr_tlch_id = ?")
        try stmt.run(toolChain.dbid)
        let stmt2 = try connection.prepare("DELETE FROM toolchains WHERE tlch_id = ?")
        try stmt2.run(toolChain.dbid)
    }


    public func listToolChains() throws -> [ToolChain] {
        var result: [ToolChain] = []

        for row in try connection.prepare(toolChains.order(toolChainId)) {
            result.append(ToolChain(dbid: row[toolChainId], name: row[toolChainName]))
        }
        return result
    }

}
