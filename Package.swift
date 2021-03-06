// swift-tools-version:5.2

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

import PackageDescription

let package = Package(
    name: "foundation-benchmarks",
    platforms: [
        .macOS(.v10_13),
    ],
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .library(
            name: "FoundationBenchmarksDB",
            targets: ["FoundationBenchmarksDB"]
        ),
        .executable(
            name: "foundation-benchmarks",
            targets: ["FoundationBenchmarks"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/swift-extras/swift-extras-base64", .branch("main")),
        .package(url: "https://github.com/stephencelis/SQLite.swift", from: "0.12.0"),
        .package(url: "https://github.com/apple/swift-argument-parser", .upToNextMinor(from: "0.3.0")),
        .package(url: "https://github.com/autimatisering/IkigaJSON.git", from: "2.0.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "FoundationBenchmarksDB",
            dependencies: [
                .product(name: "SQLite", package: "SQLite.swift"),
            ]),
        .target(
            name: "FoundationBenchmarks",
            dependencies: [
                "FoundationBenchmarksDB",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ]),
        .testTarget(
            name: "FoundationBenchmarksTests",
            dependencies: [
                "FoundationBenchmarksDB",
                .product(name: "ExtrasBase64", package: "swift-extras-base64"),
                .product(name: "IkigaJSON", package: "IkigaJSON"),
            ]),
    ]
)
