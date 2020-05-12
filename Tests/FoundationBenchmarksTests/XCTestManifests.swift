import XCTest
import FoundationBenchmarksDB
import Foundation


final class StatsLogger {

    private let db: BenchmarksDB?
    private let toolChainId: Int64?

    private var sectionId: Int64? = nil
    private var benchmarkId: Int64? = nil
    private var benchmarkName: String = ""
    private var benchmarkUnits: String = ""

    init() {
        guard let dbId = Int64(ProcessInfo.processInfo.environment["BENCHMARKS_DBID"] ?? "") else {
            print("No DBID found - not logging to DB")
            self.db = nil
            self.toolChainId = nil
            return
        }
        let db = try! BenchmarksDB()
        guard try! db.validateToolChainId(dbId) else {
            fatalError("Cant find ToolChainId: \(dbId) in database")
        }
        self.db = db
        toolChainId = dbId
    }


    func section(name: String) throws {
        sectionId = nil
        benchmarkId = nil
        benchmarkName = ""
        benchmarkUnits = ""

        print("\n\(name)")
        print(String(repeating: "-", count: name.count), terminator: "\n\n")

        if let db = self.db {
            self.sectionId = try db.addSection(name: name)
        }
    }


    func benchmark(name: String, units: String) throws {
        benchmarkName = name
        benchmarkUnits = units
        if let db = self.db {
            self.benchmarkId = try db.addBenchmark(sectionId: self.sectionId!, name: name, units: units)
        }
    }


    func addEntry(result: String) throws {
        let padding = String(repeating: " ", count: 50 - benchmarkName.count)
        print("\(benchmarkName)\(padding): \(result) \(benchmarkUnits)")
        if let db = self.db {
            try db.addEntry(toolChainId: toolChainId!, benchmarkId: benchmarkId!, result: result)
        }
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
