// swift-tools-version: 6.3

import PackageDescription

// Fixture dependency for `Composed`. Two products so the back-fill assertion
// is meaningful: `Composed` depends on exactly one of them, and the evaluation
// must report that one rather than both or none.
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
