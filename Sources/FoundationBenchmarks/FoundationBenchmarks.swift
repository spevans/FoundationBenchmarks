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

// BenchmarkCommands.swift
//
// Created on 16/05/2020
//
// Parse command line arguments and run the commands.
//

import ArgumentParser
import Foundation
import FoundationBenchmarksDB


let baseTestsName = "FoundationBenchmarksTests"
let availableTests = [
    "base64": "Base64Tests",
    "decimal": "DecimalTests",
    "json": "JSONTests",
]


struct RuntimeError: Error, CustomStringConvertible {
    var description: String
}


struct FoundationBenchmarks: ParsableCommand {
    static var configuration = CommandConfiguration(
        abstract: "A utility for benchmarking swift-corelibs-foundation using multiple Swift toolchains.",
        subcommands: [Benchmark.self, Show.self, List.self, Rename.self, Delete.self],
        defaultSubcommand: Benchmark.self
    )


    static func showBenchmarksFor(tests: [String], toolChains: [ToolChain], benchmarkDb: BenchmarksDB, asHTML html: Bool) throws {
        let testFilters = tests.map { "\($0)." }
        let benchmarks = try benchmarkDb.listBenchmarks().filter {
            if testFilters.count == 0 { return true }
            for test in testFilters {
                if $0.sectionName.hasPrefix(test) {
                    return true
                }
            }
            return false
        }
        let results = try benchmarkDb.resultsFor(toolChains: toolChains, with: benchmarks)
        if html {
            showHTMLStatsWith(results: results, forBenchmarks: benchmarks)
        } else {
            showStatsWith(results: results, forBenchmarks: benchmarks)
        }
    }
}


struct Options: ParsableArguments {
    @Option(help: "SQLite benchmarks file.")
    var filename = BenchmarksDB.defaultFilename

    @Option(help: "Prefixes to remove from all toolchain names. Comma separated listed, removed sequentially eg --remove-prefixes=swift-")
    var removePrefixes: String?

    @Option(help: "Suffixes to remove from all toolchain names. Comma separated listed, removed sequentially eg --remove-suffixes=-ubuntu20.04,-a")
    var removeSuffixes: String?

    @Flag(help: "Use HTML for output")
    var html = false

    @Option(help: "Tests")
    var tests = "all"

    @Argument(help: "Toolchains.")
    var toolchains: [String] = []

    func splitTests() throws -> [String] {
        if tests == "all" {
            return []
        }
        var filters: [String] = []
        for test in tests.split(separator: ",").map({ String($0) }) {
            guard let testname = availableTests[test] else {
                throw RuntimeError(description: "Unknown benchmark \(test). Available benchmarks: \(availableTests.keys.sorted().joined(separator: ","))")
            }
            filters.append(testname)
        }
        return filters
    }
}


extension FoundationBenchmarks {
    struct Benchmark: ParsableCommand {
        static var configuration = CommandConfiguration(abstract: "Run the benchmarks and show the results.")

        @OptionGroup()
        var options: Options

        // Find the version of a swift toolchain, using --version, of the default swfit in the path
        private func findDefaultSwiftVersion() throws -> String? {
            let pipe = Pipe()
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/bin/sh")
            process.arguments = ["-c", "swift --version" ]
            process.standardOutput = pipe.fileHandleForWriting
            try process.run()
            process.waitUntilExit()
            let input = String(data: pipe.fileHandleForReading.availableData, encoding: .utf8)
            if let parts = input?.split(separator: "\n").first?.split(separator: " ") {
                for idx in 0..<parts.count - 1 where parts[idx] == "version" {
                    return String(parts[idx + 1])
                }
            }
            return nil
        }

        func validateToolChains(benchmarkDb: BenchmarksDB, arguments: [String]) throws -> [ToolChain] {
            var toolChains: [ToolChain] = []
            let fileManager = FileManager.default

            guard !arguments.isEmpty else {
                print("No toolchain specified, running using default 'swift' executable in $PATH")
                let toolChainId = try benchmarkDb.addToolChain(name: "default")
                return [ ToolChain(dbid: toolChainId, name: "default") ]
            }

            for arg in arguments {
                let executableURL: URL?
                let baseName: String
                if arg == "default" {
                    baseName = "default-" + (try findDefaultSwiftVersion() ?? "")
                    executableURL = nil
                } else {
                    let baseURL = URL(fileURLWithPath: arg)
                    let execURL = baseURL.appendingPathComponent("usr/bin/swift")
                    guard fileManager.isExecutableFile(atPath: execURL.path) else {
                        throw RuntimeError(description: "Invalid toolchain '\(arg)': cant find exectable \(execURL.path)")
                    }
                    executableURL = execURL
                    var _baseName = baseURL.lastPathComponent
                    if let prefixes = options.removePrefixes {
                        for prefix in prefixes.split(separator: ",") {
                            if _baseName.hasPrefix(prefix) {
                                _baseName = _baseName.replacingOccurrences(of: prefix, with: "", options: .anchored)
                            }
                        }
                    }
                    if let suffixes = options.removeSuffixes {
                        for suffix in suffixes.split(separator: ",") {
                            if _baseName.hasSuffix(suffix) {
                                _baseName = _baseName.replacingOccurrences(of: suffix, with: "", options: [.anchored, .backwards])
                            }
                        }
                    }
                    baseName = _baseName
                }
                print("Adding toolchain:", baseName, "path:", executableURL?.absoluteString ?? "swift")
                let dbId = try benchmarkDb.addToolChain(name: baseName)
                toolChains.append(ToolChain(dbid: dbId, name: baseName, executableURL: executableURL))
            }

            return toolChains
        }


        func run() throws {
            let testFilters: [String] = try {
                let filters = try options.splitTests()
                return filters.count == 0 ? [ baseTestsName ] : filters.map { baseTestsName + "." + $0 }
            }()

            let benchmarkDb = try BenchmarksDB(file: options.filename)
            try benchmarkDb.createTables()
            let toolChains = try validateToolChains(benchmarkDb: benchmarkDb, arguments: options.toolchains)
            for toolChain in toolChains {
                for filter in testFilters {
                    let process = Process()
                    var env = ProcessInfo.processInfo.environment
                    env["BENCHMARKS_MODE"] = "1"
                    env["BENCHMARKS_DBID"] = toolChain.dbid.description
                    env["BENCHMARKS_DBFILE"] = options.filename
                    process.environment = env
                    let buildDir = ".build-\(toolChain.buildDirectoryName)"

                    print("Running with toolChain: \(toolChain.name) --filter \(filter) --build-path \(buildDir)")
                    if let executableURL = toolChain.executableURL {
                        process.executableURL = executableURL
                        process.arguments = ["test", "-c", "release", "--build-path", buildDir, "--filter", filter ]
                    } else {
                        process.executableURL = URL(fileURLWithPath: "/bin/sh")
                        process.arguments = ["-c", "swift test -c release --build-path \(buildDir) --filter \(filter)" ]
                    }
                    try process.run()
                    process.waitUntilExit()

                    if process.terminationStatus != 0 {
                        throw RuntimeError(description: "Failed to run test for tool chain '\(toolChain.name)'")
                    }
                }
            }
            try FoundationBenchmarks.showBenchmarksFor(tests: options.splitTests(), toolChains: toolChains,
                benchmarkDb: benchmarkDb, asHTML: options.html)
        }
    }
}


extension FoundationBenchmarks {
    struct Show: ParsableCommand {
        static var configuration = CommandConfiguration(abstract: "Show the results.")

        @OptionGroup()
        var options: Options


        func run() throws {

            let benchmarkDb = try BenchmarksDB(file: options.filename)
            var toolChains: [ToolChain] = []

            if options.toolchains.isEmpty {
                toolChains = try benchmarkDb.listToolChains()
            } else {
                for name in options.toolchains {
                    guard let toolChain = try benchmarkDb.toolChain(byName: name) else {
                        throw RuntimeError(description: "Cant find toolchain '\(name)' in results.")
                    }
                    toolChains.append(toolChain)
                }
            }

            try FoundationBenchmarks.showBenchmarksFor(tests: options.splitTests(), toolChains: toolChains,
                benchmarkDb: benchmarkDb, asHTML: options.html)
        }
    }
}


extension FoundationBenchmarks {
    struct List: ParsableCommand {
        static var configuration = CommandConfiguration(abstract: "List the available toolchains in the results file.")

        @Option(help: "SQLite benchmarks file.")
        var filename = BenchmarksDB.defaultFilename

        func run() throws {
            let benchmarkDb = try BenchmarksDB(file: filename)
            let toolChains = try benchmarkDb.listToolChains()
            toolChains.forEach {
                print("\($0.dbid):\t\($0.name)")
            }
        }
    }
}


extension FoundationBenchmarks {
    struct Rename: ParsableCommand {
        static var configuration = CommandConfiguration(abstract: "Rename a toolchain in the results file.")

        @Option(help: "SQLite benchmarks file.")
        var filename = BenchmarksDB.defaultFilename

        @Argument(help: "Toolchain to rename.")
        var toolchain: String

        @Argument(help: "New name.")
        var newName: String


        func run() throws {
            let benchmarkDb = try BenchmarksDB(file: filename)
            guard let toolChain = try benchmarkDb.toolChain(byName: toolchain) else {
                throw RuntimeError(description: "Cant find toolchain '\(toolchain)' in results.")
            }
            try benchmarkDb.renameToolChain(toolChain, to: newName)
        }
    }
}


extension FoundationBenchmarks {
    struct Delete: ParsableCommand {
        static var configuration = CommandConfiguration(abstract: "Delete a toolchain from the results file.")

        @Option(help: "SQLite benchmarks file.")
        var filename = BenchmarksDB.defaultFilename

        @Argument(help: "Toolchains.")
        var toolchains: [String]


        func run() throws {
            let benchmarkDb = try BenchmarksDB(file: filename)
            for name in toolchains {
                guard let toolChain = try benchmarkDb.toolChain(byName: name) else {
                    throw RuntimeError(description: "Cant find toolchain '\(name)' in results.")
                }
                try benchmarkDb.deleteToolChain(toolChain)
            }
        }
    }
}
