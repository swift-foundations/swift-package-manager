import Package_Manager
import Testing

extension Package.Manifest.Redirection {
    @Suite
    struct Test {
        @Suite struct Unit {}
        @Suite struct `Edge Case` {}
    }
}

extension Package.Manifest.Redirection.Test.Unit {
    private static let manifest = """
        // swift-tools-version: 6.3.3
        import PackageDescription

        let package = Package(
            name: "consumer",
            dependencies: [
                .package(url: "https://github.com/foo/swift-alpha.git", branch: "main"),
                .package(url: "https://github.com/foo/swift-beta.git", .upToNextMajor(from: "1.0.0"))
            ],
            targets: []
        )
        """

    @Test
    func `redirect rewrites the url clause to the planned path clause`() throws {
        let rewrite = try Package.Manifest.Redirection.redirect(
            Self.manifest,
            dependency: "https://github.com/foo/swift-alpha.git",
            to: "/checkouts/swift-alpha"
        )
        #expect(rewrite.planned == ".package(path: \"/checkouts/swift-alpha\")")
        #expect(rewrite.declared == ".package(url: \"https://github.com/foo/swift-alpha.git\", branch: \"main\")")
        #expect(rewrite.source.contains(rewrite.planned))
        #expect(!rewrite.source.contains("https://github.com/foo/swift-alpha.git"))
        #expect(rewrite.source.contains("https://github.com/foo/swift-beta.git"))
    }

    @Test
    func `redirect matches on derived identity, not literal url`() throws {
        let rewrite = try Package.Manifest.Redirection.redirect(
            Self.manifest,
            dependency: "https://github.com/Foo/Swift-Alpha",
            to: "/checkouts/swift-alpha"
        )
        #expect(rewrite.declared.contains("swift-alpha.git"))
    }

    @Test
    func `redirect then restore is byte-identical`() throws {
        let rewrite = try Package.Manifest.Redirection.redirect(
            Self.manifest,
            dependency: "https://github.com/foo/swift-alpha.git",
            to: "/checkouts/swift-alpha"
        )
        let restored = try Package.Manifest.Redirection.restore(
            rewrite.source,
            planned: rewrite.planned,
            declared: rewrite.declared
        )
        #expect(restored == Self.manifest)
    }
}

extension Package.Manifest.Redirection.Test.`Edge Case` {
    private static let manifest = """
        let package = Package(
            name: "consumer",
            dependencies: [
                .package(url: "https://github.com/foo/swift-alpha.git", branch: "main")
            ]
        )
        """

    @Test
    func `redirect refuses a dependency not declared by url`() {
        #expect(throws: Package.Manifest.Redirection.Error.dependencyNotDeclaredByURL(identity: "swift-delta")) {
            try Package.Manifest.Redirection.redirect(
                Self.manifest,
                dependency: "https://github.com/foo/swift-delta.git",
                to: "/checkouts/swift-delta"
            )
        }
    }

    @Test
    func `restore refuses when the composed clause is absent`() throws {
        let rewrite = try Package.Manifest.Redirection.redirect(
            Self.manifest,
            dependency: "https://github.com/foo/swift-alpha.git",
            to: "/checkouts/swift-alpha"
        )
        // The original manifest never carried the planned clause — the same
        // shape a hand-edit or an earlier restore leaves behind.
        #expect(throws: Package.Manifest.Redirection.Error.composedClauseAbsent(planned: rewrite.planned)) {
            try Package.Manifest.Redirection.restore(
                Self.manifest,
                planned: rewrite.planned,
                declared: rewrite.declared
            )
        }
    }
}
