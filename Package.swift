// swift-tools-version:4.0

import PackageDescription

let package = Package(
  name: "OA",
  dependencies: [
    .package(url: "https://github.com/apple/swift-argument-parser",
      from: "0.2.0"),
  ],
  targets: [
    .target(
      name: "oa",
      dependencies: ["ArgumentParser"]),
  ]
)
