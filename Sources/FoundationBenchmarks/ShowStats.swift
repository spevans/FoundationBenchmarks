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
private let percentageHeading = "pct"
private let firstToLast = "First to Last"


private class DiffRounding: NSDecimalNumberBehaviors {
    func roundingMode() -> NSDecimalNumber.RoundingMode { .plain }
    func scale() -> Int16 { 0 }

#if _runtime(_ObjC)
    func exceptionDuringOperation(_ operation: Selector, error: NSDecimalNumber.CalculationError,
                                  leftOperand: NSDecimalNumber, rightOperand: NSDecimalNumber?) -> NSDecimalNumber? {
        let rhs = rightOperand?.description ?? "nil"
        fatalError("NSDecimalNumber exceptionDuringOperation lhs: \(leftOperand) rhs: \(rhs)) error: \(error)")
    }
#endif
}


private func calculateDifferences(_ toolChain1: ToolChainResults, _ toolChain2: ToolChainResults,
                                  using benchmarks: [Benchmark], name: String = diffColumnHeading) -> ToolChainResults {

    var results: [Int64: String] = [:]
    var percentDiff: [Int64: Int] = [:]

    for dbId in benchmarks.map({ $0.dbid }) {
        if let previousResult = toolChain1.results[dbId], let previous = Decimal(string: previousResult),
        let currentResult = toolChain2.results[dbId], let current = Decimal(string: currentResult) {
            let difference = current - previous

            results[dbId] = difference.description
            // Decimal currently has issues returning an intValue if the mantissa > UInt64.max (bug)
            // so round it to 0dp before converting to .intValue
            let percentage = NSDecimalNumber(decimal: (difference * 100) / previous)
            percentDiff[dbId] = percentage.rounding(accordingToBehavior: DiffRounding()).intValue
        }
    }
    return ToolChainResults(toolChain: ToolChain(dbid: -1, name: name), benchmarks: benchmarks,
        results: results, pctResults: percentDiff)
}


private func resultsWithDifferences(_ results: [ToolChainResults], benchmarks: [Benchmark]) -> [ToolChainResults] {
    var fullResults = [results[0]]

    for idx in 1..<results.endIndex {
        fullResults.append(results[idx])
        fullResults.append(calculateDifferences(results[idx - 1], results[idx], using: benchmarks))
    }
    if results.count > 2, let lastResults = results.last {
        fullResults.append(calculateDifferences(results[0], lastResults, using: benchmarks, name: firstToLast))
    }
    return fullResults
}


// Render the stats in a markdown compatible table that renders nicely on Github.
func showStatsWith(results: [ToolChainResults], forBenchmarks benchmarks: [Benchmark]) {

    let fullResults = resultsWithDifferences(results, benchmarks: benchmarks)

    // Find longest section/benchmark name for padding.
    let maxSectionWidth = benchmarks.map { max($0.name.count, $0.sectionName.count) }.max() ?? 0

    // Create the separator between the heading row and the first data row
    var vSeparator = "|\(String(repeating: "-", count: maxSectionWidth + 2))|"
    for result in fullResults {
        let width = result.maxResultWidth + 2
        vSeparator += "\(String(repeating: "-", count: width))|"
        if result.isDifferenceResults {
            let width = max(result.maxPctResultWidth, percentageHeading.count) + 2
            vSeparator += "\(String(repeating: "-", count: width))|"
        }
    }

    var currentSection = ""
    for benchmark in benchmarks {
        if benchmark.sectionName != currentSection {
            currentSection = benchmark.sectionName

            // Header with Toolchain name and 'difference' / 'pct' columns
            let spacing = String(repeating: " ", count: maxSectionWidth - currentSection.count)
            print("\n| \(currentSection)\(spacing) |", terminator: "")
            for result in fullResults {
                let maxWidth = result.maxResultWidth
                let spacing = String(repeating: " ", count: maxWidth - result.toolChain.name.count)
                print(" \(spacing)\(result.toolChain.name) |", terminator: "")
                if result.isDifferenceResults {
                    let maxWidth = max(result.maxPctResultWidth, percentageHeading.count)
                    let spacing = String(repeating: " ", count: maxWidth - percentageHeading.count)
                    print(" \(spacing)\(percentageHeading) |", terminator: "")
                }
            }
            print("\n\(vSeparator)")
        }

        let spacing = String(repeating: " ", count: maxSectionWidth - benchmark.name.count)
        print("| \(benchmark.name)\(spacing) |", terminator: "")

        for toolChainResult in fullResults {
            let maxWidth = toolChainResult.maxResultWidth
            let entry: String
            if let value = toolChainResult.results[benchmark.dbid] {
                entry = "\(value) \(benchmark.units)"
            } else {
                entry = ""
            }
            print(" \(String(repeating: " ", count: maxWidth - entry.count))\(entry) |", terminator: "")

            if toolChainResult.isDifferenceResults {
                let maxWidth = max(toolChainResult.maxPctResultWidth, percentageHeading.count)
                let entry = toolChainResult.pctResultFor(benchmarkId: benchmark.dbid)
                print(" \(String(repeating: " ", count: maxWidth - entry.count))\(entry) |", terminator: "")
            }
        }
        print("")
    }
    print("")
}


private let htmlHeader = """
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
"""


// Render the stats in an HTML table.
func showHTMLStatsWith(results: [ToolChainResults], forBenchmarks benchmarks: [Benchmark]) {

    let fullResults = resultsWithDifferences(results, benchmarks: benchmarks)

    print(htmlHeader)
    var currentSection = ""
    for benchmark in benchmarks {
        if benchmark.sectionName != currentSection {
            if currentSection != "" {
                print("\t<tr><td class=\"spacer\" colspan=\"100%\"></td></tr>")
                print("    </table>\n    <!-- End of \(currentSection) -->\n")
            }

            currentSection = benchmark.sectionName

            // Header with Toolchain name and 'difference' / 'pct' columns

            print("    <!-- Start of \(currentSection) -->\n    <table>")
            print("\t<tr><th align=\"left\">\(currentSection)</th>", terminator: "")
            var oddColumn = false
            for toolChainResult in fullResults {
                if !toolChainResult.isDifferenceResults {
                    oddColumn.toggle()
                }
                let rowClass = oddColumn ? "odd" : "even"
                let colspan = toolChainResult.isDifferenceResults ? " colspan=\"2\"" : ""
                print("<th class=\"\(rowClass)\"\(colspan)>\(toolChainResult.toolChain.name)</th>", terminator: "")

            }
            print("</tr>")
        }

        print("\t<tr><td align=\"left\">\(benchmark.name)</td>", terminator: "")
        var oddColumn = false
        for toolChainResult in fullResults {
            if !toolChainResult.isDifferenceResults {
                oddColumn.toggle()
            }
            let rowClass = oddColumn ? "odd" : "even"
            if let value = toolChainResult.results[benchmark.dbid] {
                // print the value
                print("<td align=\"right\" class=\"\(rowClass)\">\(value) \(benchmark.units)</td>", terminator: "")
            } else {
                print("<td class=\"\(rowClass)\"></td>", terminator: "")
            }
            if toolChainResult.isDifferenceResults {
                let entry = toolChainResult.pctResultFor(benchmarkId: benchmark.dbid)
                print("<td align=\"right\" class=\"\(rowClass)\">\(entry)</td>", terminator: "")
            }
        }

        print("</tr>")
    }
    print("    </table>\n    <!-- End of \(currentSection) -->\n")
    print("</body>\n</html>")
}
