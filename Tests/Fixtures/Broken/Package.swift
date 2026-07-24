// swift-tools-version: 6.3

import PackageDescription

// Deliberately invalid: `swift package dump-package` must terminate
// unsuccessfully here and write a diagnostic to stderr. Used to prove the
// manager preserves stderr on command failure.
let package = Package(
