import Foundation
import FoundationBenchmarksDB


struct ToolChain {
    let name: String
    let dbid: Int64
}


func validateToolChains(arguments: ArraySlice<String>) throws -> [ToolChain] {
    var toolChains: [ToolChain] = []
    let fm = FileManager.default
    print("Connecting to db")
    let db = try BenchmarksDB()
    print("createing tables")
    try db.createTables()
    print("created tables")

    guard !arguments.isEmpty else {
        print("No toolchain specified, running using default 'swift' executable in path")
        let id = try db.addToolChain(name: "default")
        return [ ToolChain(name: "default", dbid: id) ]
    }

    for arg in arguments {
        let baseName: String
        if arg == "default" {
            baseName = arg
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
        print("Added with id:", id)
        toolChains.append(ToolChain(name: arg, dbid: id))
    }

    return toolChains
}


let toolChains = try! validateToolChains(arguments:  CommandLine.arguments.dropFirst(1))
for toolChain in toolChains {

    let process = Process()
    var env = ProcessInfo.processInfo.environment
    env["BENCHMARKS_DBID"] = toolChain.dbid.description
    process.environment = env

    if toolChain.name == "default" {
        print("Running with default toolChain")
        process.executableURL = URL(fileURLWithPath: "/bin/sh")
        process.arguments = ["-c", "swift test -c release" ]
    } else {
        print("Running with toolChain: \(toolChain.name) test -c release")
        process.executableURL = URL(fileURLWithPath: toolChain.name).appendingPathComponent("usr/bin/swift")
        process.arguments = ["test", "-c", "release" ]
    }
    try! process.run()
    process.waitUntilExit()
}
