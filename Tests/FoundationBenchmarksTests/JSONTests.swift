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
import IkigaJSON

private let runs = { runsInTestMode() ?? 10 }()

private struct SomeNumbers: Codable {
    let int: Int
    let double: Double
    let decimal: Decimal
}

private struct TestData {
    let zerosJsonData: Data
    let zeroDotZerosJsonData: Data
    let intMinsJsonData: Data
    let intMinDotZerosJsonData: Data
    let intsJsonData: Data
    let doublesJsonData: Data
    let decimalsJsonData: Data
    let someNumbersJsonData: Data
    let sampleDataLargeArray: Data
    let sampleDataArrayOfArrays: Data


    init() throws {

        let range = 50000
        let capacity = (2 * range) + 1
        let zeros = (1...capacity).map { _ in 0 }
        let intMins = (1...capacity).map { _ in Int.min }

        zerosJsonData = try JSONEncoder().encode(zeros)
        zeroDotZerosJsonData = ("[" + zeros.map { "\($0).0" }.joined(separator: ", ") + "]").data(using: .utf8)!
        intMinsJsonData = try JSONEncoder().encode(intMins)
        intMinDotZerosJsonData = ("[" + intMins.map { "\($0).0" }.joined(separator: ", ") + "]").data(using: .utf8)!

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
        intsJsonData = try JSONEncoder().encode(ints)
        doublesJsonData = try JSONEncoder().encode(doubles)
        decimalsJsonData = try JSONEncoder().encode(decimals)
        someNumbersJsonData = try JSONEncoder().encode(someNumbers)

        // Make the SampleStructure JSON a large to consume more time but repeating the elements inside on large array
        // eg [ <sample structure>, <sample structure>, ... ]
        var sampleDataLarge1 = "["
        sampleDataLarge1.reserveCapacity(SampleStructure.sampleJSON.count * 1000)
        sampleDataLarge1.append((1 ... 100).map { _ in  SampleStructure.sampleJSON }.joined(separator: ","))
        sampleDataLarge1.append("]")
        sampleDataLargeArray = sampleDataLarge1.data(using: .utf8)!

        // Now make one array where each element is the sample structure array,
        // eg [ [<sample structure>], [<sample structure>], ... ]
        var sampleDataLarge2 = "["
        sampleDataLarge2.reserveCapacity(SampleStructure.sampleJSON.count * 1000)
        sampleDataLarge2.append((1 ... 100).map { _ in "[ \(SampleStructure.sampleJSON) ]" }.joined(separator: ","))
        sampleDataLarge2.append("]")
        sampleDataArrayOfArrays = sampleDataLarge2.data(using: .utf8)!
    }
}

private let testData: TestData = {
    do {
        return try TestData()
    } catch {
        fatalError("Error setting up TestData: \(error)")
    }
}()


final class JSONTests: XCTestCase {

    static var allTests = [
        ("testDeserialization", testDeserializationNumbers),
        ("testDecoding", testDecoding),
        ("testBridging", testBridging),
        ("testSampleStructureJSON", testSampleStructureJSON),
    ]


    func testDeserializationNumbers() throws {
        try statsLogger.section()

        timing(name: "JSONSerialization.jsonObject - \"0\"", runs: runs) {
            _ = try JSONSerialization.jsonObject(with: testData.zerosJsonData)
        }

        timing(name: "JSONSerialization.jsonObject - \"0.0\"", runs: runs) {
            _ = try JSONSerialization.jsonObject(with: testData.zeroDotZerosJsonData)
        }

        timing(name: "JSONSerialization.jsonObject - \"Int.min\"", runs: runs) {
            _ = try JSONSerialization.jsonObject(with: testData.intMinsJsonData)
        }

        timing(name: "JSONSerialization.jsonObject - \"Int.min.0\"", runs: runs) {
            _ = try JSONSerialization.jsonObject(with: testData.intMinDotZerosJsonData)
        }

        timing(name: "JSONSerialization.jsonObject - Int", runs: runs) {
            _ = try JSONSerialization.jsonObject(with: testData.intsJsonData) as! [Int]
        }

        timing(name: "JSONSerialization.jsonObject - Double", runs: runs) {
            _ = try JSONSerialization.jsonObject(with: testData.doublesJsonData) as! [Double]
        }

        timing(name: "JSONSerialization.jsonObject - Decimal", runs: runs) {
            _ = try JSONSerialization.jsonObject(with: testData.decimalsJsonData) as? [NSDecimalNumber]
        }

        timing(name: "JSONSerialization.jsonObject - someNumbers", runs: runs) {
            _ = try JSONSerialization.jsonObject(with: testData.someNumbersJsonData) as! [ [String: NSNumber] ]
            //    for result in results {
            ////        _ = SomeNumbers(int: result["int"] as! Int, double: result["double"] as! Double, decimal: result["decimal"]!.decimalValue)
            //    }
        }

    }

    func testDecoding() throws {
        try statsLogger.section()

        timing(name: "JSONDecoder - \"0\" to Int", runs: runs) {
            _ = try JSONDecoder().decode([Int].self, from: testData.zerosJsonData)
        }

        timing(name: "JSONDecoder - \"0.0\" to Int", runs: runs) {
            _ = try JSONDecoder().decode([Int].self, from: testData.zeroDotZerosJsonData)
        }

        timing(name: "JSONDecoder - \"Int.min\" to Int", runs: runs) {
            _ = try JSONDecoder().decode([Int].self, from: testData.intMinsJsonData)
        }

        timing(name: "JSONDecoder - \"Int.min.0\" to Int", runs: runs) {
            _ = try JSONDecoder().decode([Int].self, from: testData.intMinsJsonData)
        }

        timing(name: "JSONDecoder - Int", runs: runs) {
            _ = try JSONDecoder().decode([Int].self, from: testData.intsJsonData)
        }

        timing(name: "JSONDecoder - Double", runs: runs) {
            _ = try JSONDecoder().decode([Double].self, from: testData.doublesJsonData)
        }

        timing(name: "JSONDecoder - Decimal", runs: runs) {
            _ = try JSONDecoder().decode([Decimal].self, from: testData.decimalsJsonData)
        }

        timing(name: "JSONDecoder - someNumbers", runs: runs) {
            _ = try JSONDecoder().decode([SomeNumbers].self, from: testData.someNumbersJsonData)
        }
    }

    func testSampleStructureJSON() throws {
        try statsLogger.section()

        timing(name: "JSONDeserialization - SampleStructure JSON Large array", runs: runs) {
            _ = try JSONSerialization.jsonObject(with: testData.sampleDataLargeArray)
        }

        timing(name: "JSONDecoder - SampleStructure JSON Large array", runs: runs) {
            _ = try JSONDecoder().decode([SampleStructure].self, from: testData.sampleDataLargeArray)
        }

        timing(name: "IkigaJSON - SampleStruct JSON Large array", runs: runs) {
            _ = try IkigaJSONDecoder().decode([SampleStructure].self, from: testData.sampleDataLargeArray)
        }


        timing(name: "JSONDeserialization - SampleStructure JSON Array of arrays", runs: runs) {
            _ = try JSONSerialization.jsonObject(with: testData.sampleDataArrayOfArrays)
        }

        timing(name: "JSONDecoder - SampleStructure JSON Array of arrays", runs: runs) {
            _ = try JSONDecoder().decode([[SampleStructure]].self, from: testData.sampleDataArrayOfArrays)
        }

        timing(name: "IkigaJSON - SampleStruct JSON Array of arrays", runs: runs) {
            _ = try IkigaJSONDecoder().decode([[SampleStructure]].self, from: testData.sampleDataArrayOfArrays)
        }
    }


    func testBridging() throws {
        try statsLogger.section()

        let zeros =  try JSONSerialization.jsonObject(with: testData.zerosJsonData)
        timing(name: "Bridging \"0\" to Int", runs: runs) {
            _  = zeros as! [Int]
        }

        timing(name: "Bridging \"0\" to Double", runs: runs) {
            _ = zeros as! [Double]
        }

        let zeroDotZeros =  try JSONSerialization.jsonObject(with: testData.zeroDotZerosJsonData)
        timing(name: "Bridging \"0.0\" to Int", runs: runs) {
            _ = zeroDotZeros as! [Int]
        }

        timing(name: "Bridging \"0.0\" to Double", runs: runs) {
            _ = zeroDotZeros as! [Double]
        }

        let intMins =  try JSONSerialization.jsonObject(with: testData.intMinsJsonData)
        timing(name: "Bridging Int.min to Int", runs: runs) {
            _ = intMins as! [Int]
        }

        timing(name: "Bridging Int.min to Double", runs: runs) {
            _ = intMins as! [Int]
        }

        let intMinDotZeros =  try JSONSerialization.jsonObject(with: testData.intMinDotZerosJsonData)
        timing(name: "Bridging \"Int.min.0\" to Int", runs: runs) {
            _ = intMinDotZeros as! [Int]
        }

        timing(name: "Bridging \"Int.min.0\" to Double", runs: runs) {
            _ = intMinDotZeros as! [Int]
        }

    }
}
