// swift-tools-version: 6.3

import PackageDescription

let package = Package(
    name: "fixture",
    products: [
        .library(name: "Fixture", targets: ["Fixture"])
    ],
    targets: [
        .target(name: "Fixture")
    ]
)
