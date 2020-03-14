// swift-tools-version:4.0

import PackageDescription

let package = Package(
  name: "floobin",
  dependencies: [
    .package(url: "https://github.com/apple/swift-argument-parser",
      from: "0.0.1"),
  ],
  targets: [
    .target(
      name: "oa",
      dependencies: ["ArgumentParser"]),
  ]
)
