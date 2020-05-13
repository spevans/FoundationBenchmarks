import Foundation
import FoundationBenchmarksDB


// Find the version, using --version, of the default swfit in the path
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


private func validateToolChains(arguments: ArraySlice<String>) throws -> [ToolChain] {
    var toolChains: [ToolChain] = []
    let fm = FileManager.default
    let db = try BenchmarksDB()
    try db.createTables()

    guard !arguments.isEmpty else {
        print("No toolchain specified, running using default 'swift' executable in path")
        let id = try db.addToolChain(name: "default")
        return [ ToolChain(dbid: id, name: "default") ]
    }

    for arg in arguments {
        let baseName: String
        if arg == "default" {
            baseName = "default-" + (findDefaultSwiftVersion() ?? "")
        } else {
            let baseURL = URL(fileURLWithPath: arg)
            let executableURL = baseURL.appendingPathComponent("usr/bin/swift")
            guard fm.isExecutableFile(atPath: executableURL.path) else {
                fatalError("Invalid toolchain \(arg): cant find exectable \(executableURL.path)")
            }
            baseName = baseURL.lastPathComponent
        }
        print("Adding toolchain:", baseName)
        let id = try db.addToolChain(name: baseName)
        toolChains.append(ToolChain(dbid: id, name: arg))
    }

    return toolChains
}


private func runTests(using toolChains: [ToolChain]) throws {
    for toolChain in toolChains {

        let process = Process()
        var env = ProcessInfo.processInfo.environment
        env["BENCHMARKS_DBID"] = toolChain.dbid.description
        process.environment = env

        print("Running with toolChain: \(toolChain.name)")
        if toolChain.name == "default" {
            process.executableURL = URL(fileURLWithPath: "/bin/sh")
            process.arguments = ["-c", "swift test -c release" ]
        } else {
            process.executableURL = URL(fileURLWithPath: toolChain.name).appendingPathComponent("usr/bin/swift")
            process.arguments = ["test", "-c", "release" ]
        }
        try! process.run()
        process.waitUntilExit()

        if process.terminationStatus != 0 {
            print("Failed to run test for tool chain '\(toolChain.name)'")
            exit(1)
        }
    }
}


let args = CommandLine.arguments.dropFirst(1)
if args.first != "--show" {
    let toolChains = try validateToolChains(arguments: args)
    try runTests(using: toolChains)
}
try showStatsIn(database: "")
