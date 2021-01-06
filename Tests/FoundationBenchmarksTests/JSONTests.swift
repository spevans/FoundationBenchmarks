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

// JSONTests.swift
//
// Created on 05/01/2021
//
// Benchmarks JSON methods.
//

import XCTest
import Foundation


final class JSONTests: XCTestCase {

    static var allTests = [
        ("test_deserialization", test_deserializationNumbers),
    ]


    func test_deserializationNumbers() throws {
        try statsLogger.section()
        let runs = runsInTestMode() ?? 10
        let range = 50000

        struct SomeNumbers: Codable {
            let int: Int
            let double: Double
            let decimal: Decimal
        }

        let capacity = (2 * range) + 1
        let zeros = (1...capacity).map { _ in 0 }
        var ints: [Int] = []
        var doubles: [Double] = []
        var decimals: [Decimal] = []
        var someNumbers: [SomeNumbers] = []

        ints.reserveCapacity(capacity)
        doubles.reserveCapacity(capacity)
        decimals.reserveCapacity(capacity)
        someNumbers.reserveCapacity(capacity)

        for i in -range...range {
            let anInt = 10000 * i
            let aDouble = Double(i) * Double("1.0001e\(i % 300)")!
            let aDecimal = Decimal(string: "\(i.description)e\(i % 127)")!

            someNumbers.append(SomeNumbers(int: anInt, double: aDouble, decimal: aDecimal))
            ints.append(anInt)
            doubles.append(aDouble)
            decimals.append(aDecimal)
        }

        let zerosJsonData = try JSONEncoder().encode(zeros)
        let intsJsonData = try JSONEncoder().encode(ints)
        let doublesJsonData = try JSONEncoder().encode(doubles)
        let decimalsJsonData = try JSONEncoder().encode(decimals)
        let someNumbersJsonData = try JSONEncoder().encode(someNumbers)

        timing(name: "JSONSerialization.jsonObject - zeros") {
            for _ in 1...runs {
                _ = try JSONSerialization.jsonObject(with: zerosJsonData)
                //XCTAssertEqual(results.count, ints.count)
            }
        }

        timing(name: "JSONSerialization.jsonObject - Int") {
            for _ in 1...runs {
                let results = try JSONSerialization.jsonObject(with: intsJsonData) as! [Int]
                XCTAssertEqual(results.count, ints.count)
            }
        }

        timing(name: "JSONSerialization.jsonObject - Double") {
            for _ in 1...runs {
                let results = try JSONSerialization.jsonObject(with: doublesJsonData) as! [Double]
                XCTAssertEqual(results.count, doubles.count)
            }
        }

        timing(name: "JSONSerialization.jsonObject - someNumbers") {
            for _ in 1...runs {
                let results = try JSONSerialization.jsonObject(with: someNumbersJsonData) as! [ [String: NSNumber] ]
                XCTAssertEqual(results.count, someNumbers.count)
                for result in results {
                    _ = SomeNumbers(int: result["int"] as! Int, double: result["double"] as! Double, decimal: result["decimal"]!.decimalValue)
                }
            }
        }

        timing(name: "JSONDecoder - zeros") {
            for _ in 1...runs {
                let results = try JSONDecoder().decode([Int].self, from: zerosJsonData)
                XCTAssertEqual(results.count, zeros.count)
            }
        }

        timing(name: "JSONDecoder - Int") {
            for _ in 1...runs {
                let results = try JSONDecoder().decode([Int].self, from: intsJsonData)
                XCTAssertEqual(results.count, ints.count)
            }
        }

        timing(name: "JSONDecoder - Double") {
            for _ in 1...runs {
                let results = try JSONDecoder().decode([Double].self, from: doublesJsonData)
                XCTAssertEqual(results.count, doubles.count)
            }
        }

        timing(name: "JSONDecoder - Decimal") {
            for _ in 1...runs {
                let results = try JSONDecoder().decode([Decimal].self, from: decimalsJsonData)
                XCTAssertEqual(results.count, decimals.count)
            }
        }

        timing(name: "JSONDecoder - someNumbers") {
            for _ in 1...runs {
                let results = try JSONDecoder().decode([SomeNumbers].self, from: someNumbersJsonData)
                XCTAssertEqual(results.count, someNumbers.count)
            }
        }
    }
}
