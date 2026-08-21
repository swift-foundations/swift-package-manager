// swift-tools-version: 6.3

import PackageDescription

let package = Package(
    name: "dependency",
    products: [
        .library(name: "Dependency Core", targets: ["Dependency Core"]),
        .library(name: "Dependency Extra", targets: ["Dependency Extra"]),
    ],
    targets: [
        .target(name: "Dependency Core"),
        .target(name: "Dependency Extra"),
    ]
)
