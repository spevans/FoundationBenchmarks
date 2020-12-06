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

// Base64Tests.swift
//
// Created on 20/11/2020
//
// Tests Decimal methods.
//

import XCTest
import Foundation


final class DecimalTests: XCTestCase {

    static var allTests = [
        ("test_DecimalInitFromDouble", test_DecimalInitFromDouble)
    ]


    // Timing for creaating a Decimal from a Double.
    func test_DecimalInitFromDouble() throws {

        try statsLogger.section(name: "DecimalTests.DecimalInitFromDouble")
        let testCount = 100000
        let randomDoubles = (1...testCount).map { Int -> Double in
            Double(bitPattern: UInt64.random(in: UInt64.min...UInt64.max))
        }

        timing(name: "Decimal.init(Double) with \(testCount) Doubles") {
            for d in randomDoubles {
                _ = Decimal(d)
            }
        }
    }
}
