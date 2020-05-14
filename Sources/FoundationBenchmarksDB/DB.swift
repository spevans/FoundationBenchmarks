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

    public init(dbid: Int64, name: String) {
        self.dbid = dbid
        self.name = name
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

    public init(dbid: Int64, name: String, units: String) {
        self.dbid = dbid
        self.name = name
        self.units = units
    }
}


public final class BenchmarksDB {

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


    public init() throws {
        connection = try Connection("benchmarks.sqlite3")
    }


    public func createTables() throws {

        _ = try connection.run (toolChains.create(ifNotExists: true) { t in
                t.column(toolChainId, primaryKey: true)
                t.column(toolChainName, unique: true)
            })

        _ = try connection.run (sections.create(ifNotExists: true) { t in
                t.column(sectionId, primaryKey: true)
                t.column(sectionName, unique: true)
            })

        _ = try connection.run (benchmarks.create(ifNotExists: true) { t in
                t.column(benchmarkId, primaryKey: true)
                t.column(benchmarkSectionId, references: sections, sectionId)
                t.column(benchmarkName)
                t.column(benchmarkUnits)
                t.unique(benchmarkSectionId, benchmarkName)
            })

        _ = try connection.run (entries.create(ifNotExists: true) { t in
                t.column(entryId, primaryKey: true)
                t.column(entryToolChainId, references: toolChains, toolChainId)
                t.column(entryBenchmarkId, references: benchmarks, benchmarkId)
                t.column(entryResult)
            })
    }


    public func validateToolChainId(_ id: Int64) throws -> Bool {
        if let row = try connection.pluck(toolChains.filter(toolChainId == id)) {
            return row[toolChainId] == id
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
        for row in benchmarkEntryQuery  {
            if let value = Int64(row[entryResult]) { return Decimal(value) }
        }
        return nil
    }


    public func listToolChains() throws -> [ToolChain] {
        var result: [ToolChain] = []

        for row in try connection.prepare(toolChains.order(toolChainId)) {
            result.append(ToolChain(dbid: row[toolChainId], name: row[toolChainName]))
        }
        return result
    }


    public func listSections() throws -> [Section] {
        var results: [Section] = []

        for row in try connection.prepare(sections.order(sectionId)) {
            var results2: [Benchmark] = []
            for row2 in try connection.prepare(benchmarks.filter(benchmarkSectionId == row[sectionId])
                .order(benchmarkId)) {
                results2.append(Benchmark(dbid: row2[benchmarkId], name: row2[benchmarkName], units: row2[benchmarkUnits]))
                }
            results.append(Section(dbid: row[sectionId], name: row[sectionName], benchmarks: results2))
        }
        return results
    }
}
