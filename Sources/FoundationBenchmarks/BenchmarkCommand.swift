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


struct RuntimeError: Error, CustomStringConvertible {
    var description: String
}


struct BenchmarkCommand: ParsableCommand {
    static var configuration = CommandConfiguration(
        abstract: "A utility for benchmarking swift-corelibs-foundation in different Swift toolchains.",
        subcommands: [Benchmark.self, Show.self, List.self, Rename.self, Delete.self],
        defaultSubcommand: Benchmark.self
    )
}


struct Options: ParsableArguments {
    @Option(default: BenchmarksDB.defaultFilename, help: "SQLite benchmarks file.")
    var filename: String

    @Option(help: "Prefixes to remove from all toolchain names.")
    var removePrefixes: String?

    @Option(help: "Suffixes to remove from all toolchain names.")
    var removeSuffixes: String?

    @Argument(help: "Toolchains.")
    var toolchains: [String]
}



extension BenchmarkCommand {
    struct Benchmark: ParsableCommand {
        static var configuration = CommandConfiguration(abstract: "Run the benchmarks and show the results.")

        @OptionGroup()
        var options: Options


        // Find the version of a swift toolchain, using --version, of the default swfit in the path
        private func findDefaultSwiftVersion() -> String? {
            let pipe = Pipe()
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/bin/sh")
            process.arguments = ["-c", "swift --version" ]
            process.standardOutput = pipe.fileHandleForWriting
            try! process.run()
            process.waitUntilExit()
            let input = String(data: pipe.fileHandleForReading.availableData, encoding: .utf8)
            if let parts = input?.split(separator: "\n").first?.split(separator: " ") {
                for idx in 0..<parts.count - 1 {
                    if parts[idx] == "version" {
                        let v = parts[idx + 1]
                        return String(v)
                    }
                }
            }
            return nil
        }

        func validateToolChains(db: BenchmarksDB, arguments: [String]) throws -> [ToolChain] {
            var toolChains: [ToolChain] = []
            let fm = FileManager.default

            guard !arguments.isEmpty else {
                print("No toolchain specified, running using default 'swift' executable in path")
                let id = try db.addToolChain(name: "default")
                return [ ToolChain(dbid: id, name: "default") ]
            }

            for arg in arguments {
                let executableURL: URL?
                let baseName: String
                if arg == "default" {
                    baseName = "default-" + (findDefaultSwiftVersion() ?? "")
                    executableURL = nil
                } else {
                    let baseURL = URL(fileURLWithPath: arg)
                    let execURL = baseURL.appendingPathComponent("usr/bin/swift")
                    guard fm.isExecutableFile(atPath: execURL.path) else {
                        throw RuntimeError(description: "Invalid toolchain \(arg): cant find exectable \(execURL.path)")
                    }
                    executableURL = execURL
                    baseName = baseURL.lastPathComponent
                }
                print("Adding toolchain:", baseName)
                let id = try db.addToolChain(name: baseName)
                toolChains.append(ToolChain(dbid: id, name: baseName, executableURL: executableURL))
            }

            return toolChains
        }


        func run() throws {
            let db = try BenchmarksDB(file: options.filename)
            try db.createTables()
            let toolChains = try validateToolChains(db: db, arguments: options.toolchains)
            for toolChain in toolChains {
                let process = Process()
                var env = ProcessInfo.processInfo.environment
                env["BENCHMARKS_DBID"] = toolChain.dbid.description
                env["BENCHMARKS_DBFILE"] = options.filename
                process.environment = env

                print("Running with toolChain: \(toolChain.name)")
                if toolChain.name == "default" {
                    process.executableURL = URL(fileURLWithPath: "/bin/sh")
                    process.arguments = ["-c", "swift test -c release" ]
                } else {
                    process.executableURL = toolChain.executableURL
                    process.arguments = ["test", "-c", "release" ]
                }
                try! process.run()
                process.waitUntilExit()

                if process.terminationStatus != 0 {
                    throw RuntimeError(description: "Failed to run test for tool chain '\(toolChain.name)'")
                }
            }
            try showStatsIn(database: db, toolChains: toolChains)
        }
    }
}


extension BenchmarkCommand {
    struct Show: ParsableCommand {
        static var configuration = CommandConfiguration(abstract: "Show the results.")

        @OptionGroup()
        var options: Options


        func run() throws {
            let db = try BenchmarksDB(file: options.filename)
            var toolChains: [ToolChain] = []

            if options.toolchains.isEmpty {
                toolChains = try db.listToolChains()
            } else {
                for name in options.toolchains {
                    guard let toolChain = try db.toolChain(name: name) else {
                        throw RuntimeError(description: "Cant find toolchain '\(name)' in results.")
                    }
                    toolChains.append(toolChain)
                }
            }
            try showStatsIn(database: db, toolChains: toolChains)
        }
    }
}


extension BenchmarkCommand {
    struct List: ParsableCommand {
        static var configuration = CommandConfiguration(abstract: "List the available toolchains in the results file.")

        @Option(default: BenchmarksDB.defaultFilename, help: "SQLite benchmarks file.")
        var filename: String

        func run() throws {
            let db = try BenchmarksDB(file: filename)
            let toolChains = try db.listToolChains()
            toolChains.forEach {
                print("\($0.dbid):\t\($0.name)")
            }
        }
    }
}


extension BenchmarkCommand {
    struct Rename: ParsableCommand {
        static var configuration = CommandConfiguration(abstract: "Rename a toolchain in the results file.")

        @Option(default: BenchmarksDB.defaultFilename, help: "SQLite benchmarks file.")
        var filename: String

        @Argument(help: "Toolchain to rename.")
        var toolchain: String

        @Argument(help: "New name.")
        var newName: String


        func run() throws {
            let db = try BenchmarksDB(file: filename)
            guard let toolChain = try db.toolChain(name: toolchain) else {
                throw RuntimeError(description: "Cant find toolchain '\(toolchain)' in results.")
            }
            try db.renameToolChain(id: toolChain.dbid, to: newName)
        }
    }
}


extension BenchmarkCommand {
    struct Delete: ParsableCommand {
        static var configuration = CommandConfiguration(abstract: "Delete a toolchain from the results file.")

        @Option(default: BenchmarksDB.defaultFilename, help: "SQLite benchmarks file.")
        var filename: String

        @Argument(help: "Toolchains.")
        var toolchains: [String]


        func run() throws {
            let db = try BenchmarksDB(file: filename)
            for name in toolchains {
                guard let toolChain = try db.toolChain(name: name) else {
                    throw RuntimeError(description: "Cant find toolchain '\(name)' in results.")
                }
                try db.deleteToolChain(id: toolChain.dbid)
            }
        }
    }
}
