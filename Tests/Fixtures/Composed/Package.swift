// swift-tools-version: 6.3

import PackageDescription

// Deterministic fixture for `evaluation(at:)`.
//
// Self-contained: the only dependency is a sibling directory reached by a
// RELATIVE path, so this fixture resolves identically on any machine and never
// consults mirror configuration. Carries one genuine `.package(path:)`
// dependency, two products, two targets, explicit platforms, and a
// `.product(name:package:)` target edge that drives the dependency-product
// back-fill.
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
