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

// ShowStats.swift
//
// Created on 13/05/2020
//
// Displays the results of the tests for each toolchain calculating differences between test runs.
//

import FoundationBenchmarksDB
import Foundation


private let diffColumnHeading = "difference"
private let percentageHeading = " pct "
private let firstToLast = "First to Last"

// Render the stats in a markdown compatible table that renders nicely on Github.
func showStatsIn(database db: BenchmarksDB, toolChains: [ToolChain]) throws {
    // Get the list of toolchains

    let sections = try db.listSections()

    // Find longest section name for padding.
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



// Render the stats in an HTML table.
func showHTMLStatsIn(database db: BenchmarksDB, toolChains: [ToolChain]) throws {

    // Get the list of toolchains
    let sections = try db.listSections()

    print("""
<html>
    <head>
    </head>
    <style>
        body {
           font-family: -apple-system, verdana, helvetia, arial, sans-serif;
        }
        table {
        border-collapse: collapse;
        }
        tbody th.even, td.even {
           background-color: #e0e0e0;
        }
        tbody th.odd, td.odd {
           background-color: #ffffff;
        }

        td, th {
            border: 1pt solid black;
            padding: 5pt;
        }
        td.spacer {
            padding: 30pt;
            border-bottom: 0pt;
            border-left: 0pt;
            border-right: 0pt;
            background-color: #ffffff;
        }
    </style>

    <body>
    <table>
""")
    for (sectionIdx, section) in sections.enumerated() {
        // Header with Toolchain name and 'difference' / 'pct' columns

        print("\t<!-- Start of \(section.name) -->")
        print("\t<tr><th align=\"left\">\(section.name)</th>", terminator: "")
        var oddRow = false
        for (idx, toolChain) in toolChains.enumerated() {
            oddRow.toggle()
            let rowClass = oddRow ? "odd" : "even"
            print("<th class=\"\(rowClass)\">\(toolChain.name)</th>", terminator: "")
            if idx != 0 {
                print("<th class=\"\(rowClass)\" colspan=\"2\">\(diffColumnHeading)</th>", terminator: "")
            }

        }
        if toolChains.count > 2 {
            print("<th colspan=\"2\">\(firstToLast)</th>", terminator: "")
        }
        print("</tr>")

        for benchmark in section.benchmarks {
            print("\t<tr><td align=\"left\">\(benchmark.name)</td>", terminator: "")

            var firstValue: Decimal? = nil
            var previousValue: Decimal? = nil
            var oddRow = false
            for toolChain in toolChains {
                oddRow.toggle()
                let rowClass = oddRow ? "odd" : "even"

                if let value = try db.benchmarkEntry(toolChainId: toolChain.dbid, benchmarkId: benchmark.dbid) {
                    // print the value
                    print("<td align=\"right\" class=\"\(rowClass)\">\(value) \(benchmark.units)</td>", terminator: "")

                    if let previous = previousValue {
                        let (diff, pct)  = calculateDiff(previous: previous, current: value, units: benchmark.units)
                        print("<td align=\"right\" class=\"\(rowClass)\">\(diff)</td>", terminator: "")
                        print("<td align=\"right\" class=\"\(rowClass)\">\(pct)</td>", terminator: "")
                    }
                    firstValue = firstValue ?? value
                    previousValue = value
                } else {
                    print("<td class=\"\(rowClass)\" colspan=\"3\"></td>", terminator: "")
                }
            }

            if toolChains.count > 2 {
                oddRow.toggle()
                let rowClass = oddRow ? "odd" : "even"
                if let first = firstValue, let last = previousValue {
                    let (diff, pct)  = calculateDiff(previous: first, current: last, units: benchmark.units)
                    print("<td align=\"right\" class=\"\(rowClass)\">\(diff)</td><td align=\"right\" class=\"\(rowClass)\">\(pct)</td>", terminator: "")
                } else {
                    print("<td class=\"\(rowClass)\" colspan=\"2\"></td>", terminator: "")
                }
            }
            print("</tr>")
        }
        print("\t<!-- End of \(section.name) -->\n")
        if sectionIdx < sections.count - 1 {
            print("\t<tr><td class=\"spacer\" colspan=\"100%\"></td></tr>\n")
        }
    }
    print("    </table>\n    </body>\n</html>")
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
