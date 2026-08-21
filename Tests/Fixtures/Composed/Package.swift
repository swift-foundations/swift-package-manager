// swift-tools-version: 6.3

import PackageDescription

let package = Package(
    name: "composed",
    platforms: [
        .macOS(.v13),
        .iOS(.v16),
    ],
    products: [
        .library(name: "Composed", targets: ["Composed"]),
        .library(name: "Composed Helper", targets: ["Composed Helper"]),
    ],
    dependencies: [
        .package(path: "../Dependency")
    ],
    targets: [
        .target(
            name: "Composed",
            dependencies: [
                .product(name: "Dependency Core", package: "dependency"),
                "Composed Helper",
            ]
        ),
        .target(name: "Composed Helper"),
    ]
)
