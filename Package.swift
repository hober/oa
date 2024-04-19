// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "OpenApp",
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser",
                 from: "1.3.1"),
        .package(url: "https://github.com/apple/swift-docc-plugin",
                 from: "1.0.0"),
        .package(url: "https://github.com/dduan/TOMLDecoder",
                 from: "0.2.2")
    ],
    targets: [
        .executableTarget(
            name: "oa",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "TOMLDecoder", package: "TOMLDecoder")
            ],
            path: "Sources"
        )
    ]
)
