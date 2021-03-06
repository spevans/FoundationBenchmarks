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
// Created on 11/05/2020
//
// Benchmarks encoding and decoding Base64 Strings.
//

import XCTest
import Foundation
import ExtrasBase64


final class Base64Tests: XCTestCase {

    static var allTests = [
        ("test_base64EncodeShortSpeed", test_base64EncodeShortSpeed),
        ("test_base64EncodeLongSpeed", test_base64EncodeLongSpeed),
        ("test_base64DecodeShortSpeed", test_base64DecodeShortSpeed),
        ("test_base64DecodeLongSpeed", test_base64DecodeLongSpeed),
    ]

    lazy var randomData: Data = {
        let count = 16 * 1024 * (runsInTestMode() ?? 1024)
        print("Base64Tests: Generating \(count) bytes of random data...", terminator: "")
        let buffer: [UInt8] = {
            return (1...count).map { _ in UInt8.random(in: 0...UInt8.max) }
        }()
        print("done")
        return Data(buffer)
    }()

    private let optionsLength64: NSData.Base64EncodingOptions = [.lineLength64Characters]
    private let optionsLength64withCR: NSData.Base64EncodingOptions = [
        .lineLength64Characters,
        .endLineWithCarriageReturn
    ]
    private let optionsLength64withLF: NSData.Base64EncodingOptions = [
        .lineLength64Characters,
        .endLineWithLineFeed
    ]
    private let optionsLength64withCRLF: NSData.Base64EncodingOptions = [
        .lineLength64Characters,
        .endLineWithCarriageReturn,
        .endLineWithLineFeed
    ]

    private let optionsLength76: NSData.Base64EncodingOptions = [.lineLength76Characters]
    private let optionsLength76withCR: NSData.Base64EncodingOptions = [
        .lineLength76Characters,
        .endLineWithCarriageReturn
    ]
    private let optionsLength76withLF: NSData.Base64EncodingOptions = [
        .lineLength76Characters,
        .endLineWithLineFeed
    ]
    private let optionsLength76withCRLF: NSData.Base64EncodingOptions = [
        .lineLength76Characters,
        .endLineWithCarriageReturn,
        .endLineWithLineFeed
    ]


    private func testWithOptions(name: String, runs: Int, execute: (_ : NSData.Base64EncodingOptions) -> Void) {
        timing(name: "\(name) - No options", runs: runs, execute: { execute([]) })
        timing(name: "\(name) - Length64", runs: runs, execute: { execute([optionsLength64]) })
        timing(name: "\(name) - Length64CR", runs: runs, execute: { execute([optionsLength64withCR]) })
        timing(name: "\(name) - Length64LF", runs: runs, execute: { execute([optionsLength64withLF]) })
        timing(name: "\(name) - Length64CRLF", runs: runs, execute: { execute([optionsLength64withCRLF]) })
        timing(name: "\(name) - Length76", runs: runs, execute: { execute([optionsLength76]) })
        timing(name: "\(name) - Length76CR", runs: runs, execute: { execute([optionsLength76withCR]) })
        timing(name: "\(name) - Length76LF", runs: runs, execute: { execute([optionsLength76withLF]) })
        timing(name: "\(name) - Length76CRLF", runs: runs, execute: { execute([optionsLength76withCRLF]) })
    }


    func test_base64EncodeShortSpeed() throws {

        try statsLogger.section()

        let runs = runsInTestMode() ?? 1000_000
        let bytes1 = Array(UInt8(0)...UInt8(255))
        let bytes2 = Array(UInt8(0)...UInt8(254))
        let bytes3 = Array(UInt8(0)...UInt8(253))

        let data1 = Data(bytes1)
        let data2 = Data(bytes2)
        let data3 = Data(bytes3)

        let nsdata1 = NSData(data: data1)
        let nsdata2 = NSData(data: data2)
        let nsdata3 = NSData(data: data3)

        let nsdata1String = nsdata1.base64EncodedString()
        let nsdata2String = nsdata2.base64EncodedString()
        let nsdata3String = nsdata3.base64EncodedString()

        let data1String = data1.base64EncodedString()
        let data2String = data2.base64EncodedString()
        let data3String = data3.base64EncodedString()

        let b64kit1String = Base64.encodeString(bytes: data1)
        let b64kit2String = Base64.encodeString(bytes: data2)
        let b64kit3String = Base64.encodeString(bytes: data3)

        XCTAssertEqual(nsdata1String, data1String)
        XCTAssertEqual(nsdata1String, b64kit1String)
        XCTAssertEqual(b64kit1String, data1String)

        XCTAssertEqual(nsdata2String, data2String)
        XCTAssertEqual(nsdata2String, b64kit2String)
        XCTAssertEqual(b64kit2String, data2String)

        XCTAssertEqual(nsdata3String, data3String)
        XCTAssertEqual(nsdata3String, b64kit3String)
        XCTAssertEqual(b64kit3String, data3String)

        let zeroByteData = Data()
        let oneByteData = Data([1])
        let twoByteData = Data([1, 2])
        let threeByteData = Data([1, 2, 3])

        let zeroByteNSData = NSData()
        let oneByteNSData = NSData(data: oneByteData)
        let twoByteNSData = NSData(data: twoByteData)
        let threeByteNSData = NSData(data: threeByteData)

        testWithOptions(name: "NSData.base64EncodedString", runs: runs) { options in
            for _ in 1...runs {
                _ = nsdata1.base64EncodedString(options: options)
                _ = nsdata2.base64EncodedString(options: options)
                _ = nsdata3.base64EncodedString(options: options)
            }
        }

        testWithOptions(name: "NSData.base64EncodedData", runs: runs) { options in
            for _ in 1...runs {
                _ = nsdata1.base64EncodedData(options: options)
                _ = nsdata2.base64EncodedData(options: options)
                _ = nsdata3.base64EncodedData(options: options)
            }
        }

        testWithOptions(name: "Data.base64EncodedString", runs: runs) { options in
            for _ in 1...runs {
                _ = data1.base64EncodedString(options: options)
                _ = data2.base64EncodedString(options: options)
                _ = data3.base64EncodedString(options: options)
            }
        }

        testWithOptions(name: "Data.base64EncodedData", runs: runs) { options in
            for _ in 1...runs {
                _ = data1.base64EncodedData(options: options)
                _ = data2.base64EncodedData(options: options)
                _ = data3.base64EncodedData(options: options)
            }
        }

        timing(name: "ExtrasBase64", runs: runs) {
            _ = Base64.encodeString(bytes: data1)
            _ = Base64.encodeString(bytes: data2)
            _ = Base64.encodeString(bytes: data3)
        }

        timing(name: "Data/NSData - 0 bytes to String", runs: runs) {
            _ = zeroByteData.base64EncodedString()
            _ = zeroByteNSData.base64EncodedString()
        }

        timing(name: "Data/NSData - 1 byte to String", runs: runs) {
            _ = oneByteData.base64EncodedString()
            _ = oneByteNSData.base64EncodedString()
        }

        timing(name: "Data/NSData - 2 bytes to String", runs: runs) {
            _ = twoByteData.base64EncodedString()
            _ = twoByteNSData.base64EncodedString()
        }

        timing(name: "Data/NSData - 3 bytes to String", runs: runs) {
            _ = threeByteData.base64EncodedString()
            _ = threeByteNSData.base64EncodedString()
        }

        timing(name: "ExtrasBase64 - 0 bytes", runs: runs) {
            _ = Base64.encodeString(bytes: zeroByteData)
            _ = Base64.encodeString(bytes: zeroByteNSData)
        }

        timing(name: "ExtrasBase64 - 1 byte", runs: runs) {
            _ = Base64.encodeString(bytes: oneByteData)
            _ = Base64.encodeString(bytes: oneByteNSData)
        }

        timing(name: "ExtrasBase64 - 2 bytes", runs: runs) {
            _ = Base64.encodeString(bytes: twoByteData)
            _ = Base64.encodeString(bytes: twoByteNSData)
        }

        timing(name: "ExtrasBase64 - 3 bytes", runs: runs) {
            _ = Base64.encodeString(bytes: threeByteData)
            _ = Base64.encodeString(bytes: threeByteNSData)
        }
    }


    func test_base64EncodeLongSpeed() throws {
        try statsLogger.section()

        let runs = runsInTestMode() ?? 100

        let data1 = randomData
        let nsdata1 = NSData(data: data1)

        let nsdata1String = nsdata1.base64EncodedString()
        let data1String = data1.base64EncodedString()
        let b64kit1String = Base64.encodeString(bytes: data1)

        XCTAssertEqual(nsdata1String, data1String)
        XCTAssertEqual(nsdata1String, b64kit1String)
        XCTAssertEqual(b64kit1String, data1String)

        testWithOptions(name: "NSData.base64EncodedString", runs: runs) { options in
            _ = nsdata1.base64EncodedString(options: options)
        }

        testWithOptions(name: "NSData.base64EncodedData", runs: runs) { options in
            _ = nsdata1.base64EncodedData(options: options)
        }

        testWithOptions(name: "Data.base64EncodedString", runs: runs) { options in
            _ = data1.base64EncodedString(options: options)
        }

        testWithOptions(name: "Data.base64EncodedData", runs: runs) { options in
            _ = data1.base64EncodedData(options: options)
        }

        timing(name: "ExtrasBase64", runs: runs) {
            _ = Base64.encodeString(bytes: data1)
        }
    }


    func test_base64DecodeShortSpeed() throws {
        try statsLogger.section()

        let runs = runsInTestMode() ?? 1000_000
        let bytes1 = Array(UInt8(0)...UInt8(255))
        let data1 = Data(bytes1)
        let encodedData1 = data1.base64EncodedData()
        let encodedString1 = data1.base64EncodedString()

        let bytes2 = Array(UInt8(0)...UInt8(254))
        let data2 = Data(bytes2)
        let encodedData2 = data2.base64EncodedData()
        let encodedString2 = data2.base64EncodedString()

        let bytes3 = Array(UInt8(0)...UInt8(253))
        let data3 = Data(bytes3)
        let encodedData3 = data3.base64EncodedData()
        let encodedString3 = data3.base64EncodedString()

        // NSData methods
        timing(name: "NSData-decodeString", runs: runs) {
            _ = NSData(base64Encoded: encodedString1)
            _ = NSData(base64Encoded: encodedString2)
            _ = NSData(base64Encoded: encodedString3)
        }

        timing(name: "NSData-decodeString - Ignore Unknown", runs: runs) {
            _ = NSData(base64Encoded: encodedString1, options: .ignoreUnknownCharacters)
            _ = NSData(base64Encoded: encodedString2, options: .ignoreUnknownCharacters)
            _ = NSData(base64Encoded: encodedString3, options: .ignoreUnknownCharacters)
        }

        timing(name: "NSData-decodeData", runs: runs) {
            _ = NSData(base64Encoded: encodedData1)
            _ = NSData(base64Encoded: encodedData2)
            _ = NSData(base64Encoded: encodedData3)
        }

        timing(name: "NSData-decodeData - Ignore Unknown", runs: runs) {
            _ = NSData(base64Encoded: encodedData1, options: .ignoreUnknownCharacters)
            _ = NSData(base64Encoded: encodedData2, options: .ignoreUnknownCharacters)
            _ = NSData(base64Encoded: encodedData3, options: .ignoreUnknownCharacters)
        }

        // Data methods
        timing(name: "Data-decodeString", runs: runs) {
            _ = Data(base64Encoded: encodedString1)!
            _ = Data(base64Encoded: encodedString2)!
            _ = Data(base64Encoded: encodedString3)!
        }

        timing(name: "Data-decodeString - Ignore Unknown", runs: runs) {
            _ = Data(base64Encoded: encodedString1, options: .ignoreUnknownCharacters)!
            _ = Data(base64Encoded: encodedString2, options: .ignoreUnknownCharacters)!
            _ = Data(base64Encoded: encodedString3, options: .ignoreUnknownCharacters)!
        }

        timing(name: "Data-decodeData", runs: runs) {
            _ = Data(base64Encoded: encodedData1)
            _ = Data(base64Encoded: encodedData2)
            _ = Data(base64Encoded: encodedData3)
        }

        timing(name: "Data-decodeData - Ignore Unknown", runs: runs) {
            _ = Data(base64Encoded: encodedData1, options: .ignoreUnknownCharacters)
            _ = Data(base64Encoded: encodedData2, options: .ignoreUnknownCharacters)
            _ = Data(base64Encoded: encodedData3, options: .ignoreUnknownCharacters)
        }

        timing(name: "ExtrasBase64", runs: runs) {
            _ = try encodedString1.base64decoded()
            _ = try encodedString2.base64decoded()
            _ = try encodedString3.base64decoded()
        }
    }


    func test_base64DecodeLongSpeed() throws {
        try statsLogger.section()

        let runs = runsInTestMode() ?? 100
        let data1 = randomData
        let encodedData1 = data1.base64EncodedData()
        let encodedString1 = data1.base64EncodedString()

        // NSData methods
        timing(name: "NSData-decodeString", runs: runs) {
            _ = NSData(base64Encoded: encodedString1)
        }

        timing(name: "NSData-decodeString - Ignore Unknown", runs: runs) {
            _ = NSData(base64Encoded: encodedString1, options: .ignoreUnknownCharacters)
        }

        timing(name: "NSData-decodeData", runs: runs) {
            _ = NSData(base64Encoded: encodedData1)
        }

        timing(name: "NSData-decodeData - Ignore Unknown", runs: runs) {
            _ = NSData(base64Encoded: encodedData1, options: .ignoreUnknownCharacters)
        }

        // Data methods
        timing(name: "Data-decodeString", runs: runs) {
            _ = Data(base64Encoded: encodedString1)!
        }

        timing(name: "Data-decodeString - Ignore Unknown", runs: runs) {
            _ = Data(base64Encoded: encodedString1, options: .ignoreUnknownCharacters)!
        }

        timing(name: "Data-decodeData", runs: runs) {
            _ = Data(base64Encoded: encodedData1)!
        }

        timing(name: "Data-decodeData - Ignore Unknown", runs: runs) {
            _ = Data(base64Encoded: encodedData1, options: .ignoreUnknownCharacters)!
        }

        timing(name: "ExtrasBase64", runs: runs) {
            _ = try encodedString1.base64decoded()
        }
    }
}
