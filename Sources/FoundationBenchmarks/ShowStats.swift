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
                                  using benchmarks: [Benchmark], name: String = diffColumnHeading,
                                  differencesOnly: Bool = false) -> ToolChainResults {

    var differences: [Int64: String] = [:]
    var percentDiff: [Int64: Int] = [:]

    for dbId in benchmarks.map({ $0.dbid }) {
        if let previousResult = toolChain1.results?[dbId], let previous = Decimal(string: previousResult),
           let currentResult = toolChain2.results?[dbId], let current = Decimal(string: currentResult) {
            let difference = current - previous

            differences[dbId] = difference.description
            // Decimal currently has issues returning an intValue if the mantissa > UInt64.max (bug)
            // so round it to 0dp before converting to .intValue
            let percentage = NSDecimalNumber(decimal: (difference * 100) / previous)
            percentDiff[dbId] = percentage.rounding(accordingToBehavior: DiffRounding()).intValue
        }
    }
    let toolChain = differencesOnly ? ToolChain(dbid: -1, name: name) : toolChain2.toolChain
    return ToolChainResults(toolChain: toolChain, benchmarks: benchmarks,
                            results: differencesOnly ? nil : toolChain2.results,
                            differences: differences, pctDifferences: percentDiff)
}


private func resultsWithDifferences(_ results: [ToolChainResults], benchmarks: [Benchmark]) -> [ToolChainResults] {
    var fullResults = [results[0]]

    for idx in 1..<results.endIndex {
       // fullResults.append(results[idx])
        fullResults.append(calculateDifferences(results[idx - 1], results[idx], using: benchmarks))
    }
    if results.count > 2, let lastResults = results.last {
        fullResults.append(calculateDifferences(results[0], lastResults, using: benchmarks, name: firstToLast, differencesOnly: true))
    }
    return fullResults
}


func firstToLastDescription(results: [ToolChainResults]) -> String? {
    if results.count > 1, let first = results.first?.toolChain.name, let last = results.last?.toolChain.name {
        return "First to Last compares \(first) to \(last)"
    } else {
        return nil
    }
}


// Render the stats in a markdown compatible table that renders nicely on Github.
func showStatsWith(results: [ToolChainResults], forBenchmarks benchmarks: [Benchmark]) {

    let fullResults = resultsWithDifferences(results, benchmarks: benchmarks)

    if let description = firstToLastDescription(results: results) {
        print("\n\(description)")
    }
    // Find longest section/benchmark name for padding.
    let maxSectionWidth = benchmarks.map { max($0.name.count, $0.sectionName.count) }.max() ?? 0

    // Create the separator between the heading row and the first data row
    var vSeparator = "|\(String(repeating: "-", count: maxSectionWidth + 2))|"
    for result in fullResults {
        vSeparator += "\(String(repeating: "-", count: result.maxTotalWidth + 2))|"
    }

    var currentSection = ""
    for benchmark in benchmarks {
        if benchmark.sectionName != currentSection {
            currentSection = benchmark.sectionName

            // Header with Toolchain name.
            let spacing = String(repeating: " ", count: maxSectionWidth - currentSection.count)
            print("\n| \(currentSection)\(spacing) |", terminator: "")
            for result in fullResults {
                let maxWidth = result.maxTotalWidth
                let spacing = String(repeating: " ", count: maxWidth - result.toolChain.name.count)
                print(" \(spacing)\(result.toolChain.name) |", terminator: "")
            }
            print("\n\(vSeparator)")
        }

        let spacing = String(repeating: " ", count: maxSectionWidth - benchmark.name.count)
        print("| \(benchmark.name)\(spacing) |", terminator: "")

        var fullLine = ""
        for toolChainResult in fullResults {
            var fullEntry = ""
            if let result = toolChainResult.results?[benchmark.dbid] {
                let entry = "\(result) \(benchmark.units)"
                let padding = toolChainResult.maxResultWidth - entry.count
                fullEntry.append(String(repeating: " ", count: padding))
                fullEntry.append(entry)
            } else {
                fullEntry.append(String(repeating: " ", count: toolChainResult.maxResultWidth))
            }

            if let difference = toolChainResult.differences?[benchmark.dbid] {
                let entry = "\(difference) \(benchmark.units)"
                let padding = toolChainResult.maxDifferencesWidth - entry.count
                fullEntry.append(String(repeating: " ", count: padding))
                fullEntry.append(entry)
            } else {
                fullEntry.append(String(repeating: " ", count: toolChainResult.maxDifferencesWidth))
            }

            if let pctDifference = toolChainResult.pctDifferences?[benchmark.dbid] {
                let entry = "\(pctDifference)%"
                let padding = toolChainResult.maxPctDifferencesWidth - entry.count
                fullEntry.append(String(repeating: " ", count: padding))
                fullEntry.append(entry)
            } else {
                fullEntry.append(String(repeating: " ", count: toolChainResult.maxPctDifferencesWidth))
            }

            let fullEntryWidth = toolChainResult.maxResultWidth + toolChainResult.maxDifferencesWidth + toolChainResult.maxPctDifferencesWidth
            let maxWidth = max(toolChainResult.toolChain.name.count, fullEntryWidth)
            fullLine.append(" \(String(repeating: " ", count: maxWidth - fullEntry.count))\(fullEntry) |")

        }
        print(fullLine)
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
            padding: 10pt;
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

    if let description = firstToLastDescription(results: results) {
        print("<br/><h3>\(description)</h3>")
    }

    var currentSection = ""
    print("\t<table>\n")
    for benchmark in benchmarks {
        if benchmark.sectionName != currentSection {
            if currentSection != "" {
                print("\t<tr><td class=\"spacer\" colspan=\"100%\"></td></tr>")
                print("\n\t<!-- End of \(currentSection) -->\n")
            }

            currentSection = benchmark.sectionName

            // Header with Toolchain name and 'difference' / 'pct' columns
            print("\t<!-- Start of \(currentSection) -->\n")
            print("\t<tr><th align=\"left\">\(currentSection)</th>", terminator: "")
            var oddColumn = false
            for toolChainResult in fullResults {
                oddColumn.toggle()
                let rowClass = oddColumn ? "odd" : "even"

                let colspan = (toolChainResult.hasResults ? 1 : 0) + (toolChainResult.hasDifferences ? 2 : 0)
                precondition(colspan != 0)
                print("<th class=\"\(rowClass)\" colspan=\"\(colspan)\">\(toolChainResult.toolChain.name)</th>", terminator: "")
            }
            print("</tr>")
        }

        print("\t<tr><td align=\"left\">\(benchmark.name)</td>", terminator: "")
        var oddColumn = false

        for toolChainResult in fullResults {
            oddColumn.toggle()
            let rowClass = oddColumn ? "odd" : "even"
            if let value = toolChainResult.results?[benchmark.dbid] {
                // print the value
                print("<td align=\"right\" class=\"\(rowClass)\">\(value) \(benchmark.units)</td>", terminator: "")
            }

            if let difference = toolChainResult.differences?[benchmark.dbid], let pctDifference = toolChainResult.pctDifferences?[benchmark.dbid] {
                // print the difference / percentage
                print("<td align=\"right\" class=\"\(rowClass)\">\(difference) \(benchmark.units)</td>", terminator: "")
                let entry = pctDifference > 0 ? "+\(pctDifference)" : "\(pctDifference)"
                print("<td align=\"right\" class=\"\(rowClass)\">\(entry) %</td>", terminator: "")
            }
        }

        print("</tr>")
    }
    print("\t<!-- End of \(currentSection) -->\n\t</table>")
    print("    </body>\n</html>")
}
