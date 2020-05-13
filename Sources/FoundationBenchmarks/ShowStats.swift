import FoundationBenchmarksDB
import Foundation


// Render the stats in a markdown compatible table that renders nicely on Github.
func showStatsIn(database: String) throws {
    let db = try BenchmarksDB()

    let diffColumnHeading = "difference"
    let percentageHeading = " pct "
    let firstToLast = "First to Last"
    // Get the list of toolchains

    let toolChains = try db.listToolChains()
    let sections = try db.listSections()

    // Find longed section name for padding
    var maxLength = 0
    for section in sections {
        maxLength = max(maxLength, section.name.count)
        for benchmark in section.benchmarks {
            maxLength = max(maxLength, benchmark.name.count)
        }
    }

    // Create the separator between the heading row and the first data row
    var vSeparator = "|\(String(repeating: "-", count: maxLength + 2))|"
    for (idx, toolChain) in toolChains.enumerated() {
        let width = toolChain.name.count + 2
        vSeparator += "\(String(repeating: "-", count: width))|"
        if (idx != 0) {
            let width1 = diffColumnHeading.count + 2
            vSeparator += "\(String(repeating: "-", count: width1))|"
            let width2 = percentageHeading.count + 2
            vSeparator += "\(String(repeating: "-", count: width2))|"

        }
    }

    if toolChains.count > 2 {
        let width1 = firstToLast.count + 2
        vSeparator += "\(String(repeating: "-", count: width1))|"
        let width2 = percentageHeading.count + 2
        vSeparator += "\(String(repeating: "-", count: width2))|"
    }

    print("")
    for section in sections {
        // Header with Toolchain name and 'difference' / 'pct' columns
        print("| \(section.name)\(String(repeating: " ", count: maxLength - section.name.count)) |", terminator: "")
        for (idx, toolChain) in toolChains.enumerated() {
            print(" \(toolChain.name) |", terminator: "")
            if idx != 0 {
                print(" \(diffColumnHeading) | \(percentageHeading) |", terminator: "")
            }

        }
        if toolChains.count > 2 {
            print(" \(firstToLast) | \(percentageHeading) |", terminator: "")
        }

        print("")
        print(vSeparator)

        for benchmark in section.benchmarks {
            print("| \(benchmark.name)\(String(repeating: " ", count: maxLength - benchmark.name.count)) |", terminator: "")

            var firstValue: Decimal? = nil
            var previousValue: Decimal? = nil
            for toolChain in toolChains {

                if let value = try db.benchmarkEntry(toolChainId: toolChain.dbid, benchmarkId: benchmark.dbid) {
                    // print the value
                    let entry = "\(value) \(benchmark.units)"
                    let width = max(toolChain.name.count - entry.count, 0)
                    print(" \(String(repeating: " ", count: width))\(entry) |", terminator: "")

                    if let previous = previousValue {
                        let (diff, pct)  = calculateDiff(previous: previous, current: value, units: benchmark.units)
                        let diffWidth = max(diffColumnHeading.count - diff.count, 0)
                        print(" \(String(repeating: " ", count: diffWidth))\(diff) |", terminator: "")
                        let pctWidth = max(percentageHeading.count - pct.count, 0)
                        print(" \(String(repeating: " ", count: pctWidth))\(pct) |", terminator: "")
                    }
                    firstValue = firstValue ?? value
                    previousValue = value
                } else {
                    print(" \(String(repeating: " ", count: toolChain.name.count)) |", terminator: "")
                    print(" \(String(repeating: " ", count: diffColumnHeading.count)) |", terminator: "")
                    print(" \(String(repeating: " ", count: percentageHeading.count)) |", terminator: "")
                }
            }

            if toolChains.count > 2 {
                if let first = firstValue, let last = previousValue {
                    let (diff, pct)  = calculateDiff(previous: first, current: last, units: benchmark.units)
                    let diffWidth = max(firstToLast.count - diff.count, 0)
                    print(" \(String(repeating: " ", count: diffWidth))\(diff) |", terminator: "")
                    let pctWidth = max(percentageHeading.count - pct.count, 0)
                    print(" \(String(repeating: " ", count: pctWidth))\(pct) |", terminator: "")
                } else {
                    print(" \(String(repeating: " ", count: firstToLast.count)) |", terminator: "")
                    print(" \(String(repeating: " ", count: percentageHeading.count)) |", terminator: "")
                }
            }
            print("")
        }

        print("")
    }
}


private class DiffRounding: NSDecimalNumberBehaviors {
    func roundingMode() -> NSDecimalNumber.RoundingMode { .plain }
    func scale() -> Int16 { 0 }

#if _runtime(_ObjC)
    func exceptionDuringOperation(_ operation: Selector,
                        error: NSDecimalNumber.CalculationError,
                  leftOperand: NSDecimalNumber,
        rightOperand: NSDecimalNumber?) -> NSDecimalNumber? {
        let rhs = rightOperand?.description ?? "nil"
        fatalError("NSDecimalNumber exceptionDuringOperation lhs: \(leftOperand) rhs: \(rhs)) error: \(error)")
    }
#endif
}


func calculateDiff(previous: Decimal, current: Decimal, units: String) -> (String, String) {
    let difference = current - previous
    let percentage: String

    // Decimal currently has issues returning an intValue if the mantissa > UInt64.max (bug)
    // so round it to 0dp before converting to .intValue
    if difference < 0 {
        percentage = NSDecimalNumber(decimal: (difference * 100) / previous).rounding(accordingToBehavior: DiffRounding()).description
    } else {
        percentage = "+" + NSDecimalNumber(decimal: (difference * 100) / previous).rounding(accordingToBehavior: DiffRounding()).description
    }
    return ("\(difference) \(units)", "\(percentage)%")
}
