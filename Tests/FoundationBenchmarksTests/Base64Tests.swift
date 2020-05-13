import XCTest
import Foundation
import Base64Kit


final class Base64Tests: XCTestCase {

    static var allTests = [
        ("test_base64EncodeShortSpeed", test_base64EncodeShortSpeed),
        ("test_base64EncodeLongSpeed", test_base64EncodeLongSpeed),
        ("test_base64DecodeShortSpeed", test_base64DecodeShortSpeed),
        ("test_base64DecodeLongSpeed", test_base64DecodeLongSpeed),
    ]

    let randomData: [UInt8] = {
        return (1...16 * 1024 * 1024).map { _ in UInt8.random(in: 0...UInt8.max) }
    }()


    override func setUp() {
        assert(false, "Compile with optimisations")
    }


    private func timing(name: String, execute: () -> ()) {
        let start = Date()
        execute()
        let time = Decimal(Int(-start.timeIntervalSinceNow * 1000))
        try! statsLogger.benchmark(name: name, units: "ms")
        try! statsLogger.addEntry(result: time)
    }

    private let optionsLength64: NSData.Base64EncodingOptions = [.lineLength64Characters]
    private let optionsLength64withCR: NSData.Base64EncodingOptions = [.lineLength64Characters, .endLineWithCarriageReturn]
    private let optionsLength64withLF: NSData.Base64EncodingOptions = [.lineLength64Characters, .endLineWithLineFeed]
    private let optionsLength64withCRLF: NSData.Base64EncodingOptions = [.lineLength64Characters, .endLineWithCarriageReturn, .endLineWithLineFeed, ]

    private let optionsLength76: NSData.Base64EncodingOptions = [.lineLength76Characters]
    private let optionsLength76withCR: NSData.Base64EncodingOptions = [.lineLength76Characters, .endLineWithCarriageReturn]
    private let optionsLength76withLF: NSData.Base64EncodingOptions = [.lineLength76Characters, .endLineWithLineFeed]
    private let optionsLength76withCRLF: NSData.Base64EncodingOptions = [.lineLength76Characters, .endLineWithCarriageReturn, .endLineWithLineFeed, ]


    private func testWithOptions(name: String, execute: (_ : NSData.Base64EncodingOptions) -> ()) {
        timing(name: "\(name) - No options", execute: { execute([]) })
        timing(name: "\(name) - Length64", execute: { execute([optionsLength64]) })
        timing(name: "\(name) - Length64CR", execute: { execute([optionsLength64withCR]) })
        timing(name: "\(name) - Length64LF", execute: { execute([optionsLength64withLF]) })
        timing(name: "\(name) - Length64CRLF", execute: { execute([optionsLength64withCRLF]) })
        timing(name: "\(name) - Length76", execute: { execute([optionsLength76]) })
        timing(name: "\(name) - Length76CR", execute: { execute([optionsLength76withCR]) })
        timing(name: "\(name) - Length76LF", execute: { execute([optionsLength76withLF]) })
        timing(name: "\(name) - Length76CRLF", execute: { execute([optionsLength76withCRLF]) })
    }


    func test_base64EncodeShortSpeed() throws {

        try statsLogger.section(name: "Base64Tests.base64EncodeShortSpeed")

        let runs = 1000_000
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

        let b64kit1String = Base64.encode(bytes: data1)
        let b64kit2String = Base64.encode(bytes: data2)
        let b64kit3String = Base64.encode(bytes: data3)

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

        testWithOptions(name: "Foundation-nsdata-toString") { options in
            for _ in 1...runs {
                _ = nsdata1.base64EncodedString(options: options)
                _ = nsdata2.base64EncodedString(options: options)
                _ = nsdata3.base64EncodedString(options: options)
            }
        }

        testWithOptions(name: "Foundation-nsdata-toData") { options in
            for _ in 1...runs {
                _ = nsdata1.base64EncodedData(options: options)
                _ = nsdata2.base64EncodedData(options: options)
                _ = nsdata3.base64EncodedData(options: options)
            }
        }

        testWithOptions(name: "Foundation-data-toString") { options in
            for _ in 1...runs {
                _ = data1.base64EncodedString(options: options)
                _ = data2.base64EncodedString(options: options)
                _ = data3.base64EncodedString(options: options)
            }
        }

        testWithOptions(name: "Foundation-data-toData") { options in
            for _ in 1...runs {
                _ = data1.base64EncodedData(options: options)
                _ = data2.base64EncodedData(options: options)
                _ = data3.base64EncodedData(options: options)
            }
        }

        timing(name: "Base64Kit") {
            for _ in 1...runs {
                _ = Base64.encode(bytes: data1)
                _ = Base64.encode(bytes: data2)
                _ = Base64.encode(bytes: data3)
            }
        }

        timing(name: "Foundation - 0 bytes") {
            for _ in 1...runs {
                _ = zeroByteData.base64EncodedString()
                _ = zeroByteNSData.base64EncodedString()
            }
        }

        timing(name: "Foundation - 1 byte") {
            for _ in 1...runs {
                _ = oneByteData.base64EncodedString()
                _ = oneByteData.base64EncodedData()
            }
        }

        timing(name: "Foundation - 2 bytes") {
            for _ in 1...runs {
                _ = twoByteData.base64EncodedString()
                _ = twoByteData.base64EncodedData()
            }
        }

        timing(name: "Foundation - 3 bytes") {
            for _ in 1...runs {
                _ = threeByteData.base64EncodedString()
                _ = threeByteData.base64EncodedData()
            }
        }

        timing(name: "Base64Kit - 0 bytes") {
            for _ in 1...runs {
                _ = Base64.encode(bytes: zeroByteData)
                _ = Base64.encode(bytes: zeroByteNSData)
            }
        }

        timing(name: "Base64Kit - 1 byte") {
            for _ in 1...runs {
                _ = Base64.encode(bytes: oneByteData)
                _ = Base64.encode(bytes: oneByteNSData)
            }
        }

        timing(name: "Base64Kit - 2 bytes") {
            for _ in 1...runs {
                _ = Base64.encode(bytes: twoByteData)
                _ = Base64.encode(bytes: twoByteNSData)
            }
        }

        timing(name: "Base64Kit - 3 bytes") {
            for _ in 1...runs {
                _ = Base64.encode(bytes: threeByteData)
                _ = Base64.encode(bytes: threeByteNSData)
            }
        }
    }


    func test_base64EncodeLongSpeed() throws {
        try statsLogger.section(name: "Base64Tests.base64EncodeLongSpeed")

        let runs = 100

        let data1 = Data(randomData)
        let nsdata1 = NSData(data: data1)

        let nsdata1String = nsdata1.base64EncodedString()

        let data1String = data1.base64EncodedString()

        let b64kit1String = Base64.encode(bytes: data1)

        XCTAssertEqual(nsdata1String, data1String)
        XCTAssertEqual(nsdata1String, b64kit1String)
        XCTAssertEqual(b64kit1String, data1String)

        testWithOptions(name: "Foundation-nsdata-toString") { options in
            for _ in 1...runs {
                _ = nsdata1.base64EncodedString(options: options)
            }
        }

        testWithOptions(name: "Foundation-nsdata-toData") { options in
            for _ in 1...runs {
                _ = nsdata1.base64EncodedData(options: options)
            }
        }

        testWithOptions(name: "Foundation-data-toString") { options in
            for _ in 1...runs {
                _ = data1.base64EncodedString(options: options)
            }
        }

        testWithOptions(name: "Foundation-data-toData") { options in
            for _ in 1...runs {
                _ = data1.base64EncodedData(options: options)
            }
        }

        timing(name: "Base64Kit") {
            for _ in 1...runs {
                _ = Base64.encode(bytes: data1)
            }
        }
    }


    func test_base64DecodeShortSpeed() throws {
        try statsLogger.section(name: "Base64Tests.base64DecodeShortSpeed")

        let runs = 1000_000
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

        timing(name: "nsdata-decodeString") {
            for _ in 1...runs {
                _ = NSData(base64Encoded: encodedString1)
                _ = NSData(base64Encoded: encodedString2)
                _ = NSData(base64Encoded: encodedString3)
            }
        }

        timing(name: "nsdata-decodeString - Ignore Unknown") {
            for _ in 1...runs {
                _ = NSData(base64Encoded: encodedString1, options: .ignoreUnknownCharacters)
                _ = NSData(base64Encoded: encodedString2, options: .ignoreUnknownCharacters)
                _ = NSData(base64Encoded: encodedString3, options: .ignoreUnknownCharacters)
            }
        }

        timing(name: "nsdata-decodeData") {
            for _ in 1...runs {
                _ = NSData(base64Encoded: encodedData1)
                _ = NSData(base64Encoded: encodedData2)
                _ = NSData(base64Encoded: encodedData3)
            }
        }

        timing(name: "nsdata-decodeData - Ignore Unknown") {
            for _ in 1...runs {
                _ = NSData(base64Encoded: encodedData1, options: .ignoreUnknownCharacters)
                _ = NSData(base64Encoded: encodedData2, options: .ignoreUnknownCharacters)
                _ = NSData(base64Encoded: encodedData3, options: .ignoreUnknownCharacters)
            }
        }

        timing(name: "Base64kit") {
            for _ in 1...runs {
	        _ = try! encodedString1.base64decoded()
	        _ = try! encodedString2.base64decoded()
	        _ = try! encodedString3.base64decoded()
	    }
        }
    }


    func test_base64DecodeLongSpeed() throws {
        try statsLogger.section(name: "Base64Tests.base64DecodeLongSpeed")

        let runs = 100
        let data1 = Data(randomData)
        let encodedData1 = data1.base64EncodedData()
        let encodedString1 = data1.base64EncodedString()

        timing(name: "nsdata-decodeString") {
            for _ in 1...runs {
                _ = NSData(base64Encoded: encodedString1)
            }
        }

        timing(name: "nsdata-decodeString - Ignore Unknown") {
            for _ in 1...runs {
                _ = NSData(base64Encoded: encodedString1, options: .ignoreUnknownCharacters)
            }
        }

        timing(name: "nsdata-decodeData") {
            for _ in 1...runs {
                _ = NSData(base64Encoded: encodedData1)
            }
        }

        timing(name: "nsdata-decodeData - Ignore Unknown") {
            for _ in 1...runs {
                _ = NSData(base64Encoded: encodedData1, options: .ignoreUnknownCharacters)
            }
        }

        timing(name: "Base64kit") {
            for _ in 1...runs {
	        _ = try! encodedString1.base64decoded()
	    }
        }
    }
}
