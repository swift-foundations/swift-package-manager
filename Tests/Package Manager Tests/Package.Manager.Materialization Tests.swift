import Package_Manager
import Testing

extension Package.Manager {
    /// Tests for ``Package/Manager/Materialized/source(of:at:scratch:)``.
    ///
    /// Pure value derivation — no filesystem, no SwiftPM invocation — so every
    /// case is deterministic and portable. Paths here are the artificial
    /// `/fixture/...` form; no machine directory appears.
    @Suite
    struct `Materialization Test` {

        private static func reference(
            _ identity: Swift.String,
            kind: Package.Resolution.Reference.Kind,
            location: Swift.String
        ) -> Package.Resolution.Reference {
            .init(identity: .init(identity), kind: kind, location: location, name: identity)
        }

        @Test
        func `a managed checkout compiles from the scratch directory, not its location`() {
            // The load-bearing case. Under an active mirror the reference
            // location is a mutable worktree that routinely diverges from what
            // was compiled, so returning it would be the exact error this
            // operation exists to prevent.
            let dependency = Package.Resolution.Dependency(
                reference: Self.reference(
                    "swift-paths",
                    kind: .localSourceControl,
                    location: "/fixture/worktrees/swift-paths"
                ),
                state: .sourceControlCheckout(.init(revision: "9bbec44", pin: .branch("main"))),
                subpath: "swift-paths"
            )

            let path = Package.Manager().materialized
                .source(of: dependency, at: "/fixture/root")

            #expect(path == "/fixture/root/.build/checkouts/swift-paths")
            // Emphatically NOT the reference location.
            #expect(path != dependency.reference.location)
        }

        @Test
        func `an explicit scratch directory overrides the default`() {
            let dependency = Package.Resolution.Dependency(
                reference: Self.reference(
                    "swift-paths",
                    kind: .localSourceControl,
                    location: "/fixture/worktrees/swift-paths"
                ),
                state: .sourceControlCheckout(.init(revision: "9bbec44", pin: .branch("main"))),
                subpath: "swift-paths"
            )

            let path = Package.Manager().materialized.source(
                of: dependency,
                at: "/fixture/root",
                scratch: "/fixture/scratch"
            )

            #expect(path == "/fixture/scratch/checkouts/swift-paths")
        }

        @Test
        func `a filesystem dependency compiles from its recorded path`() {
            // Used in place: no checkout intervenes, so the scratch directory
            // is irrelevant and must not appear in the result.
            let dependency = Package.Resolution.Dependency(
                reference: Self.reference(
                    "swift-css",
                    kind: .fileSystem,
                    location: "/fixture/packages/swift-css"
                ),
                state: .fileSystem(path: "/fixture/packages/swift-css"),
                subpath: "swift-css"
            )

            let path = Package.Manager().materialized
                .source(of: dependency, at: "/fixture/root", scratch: "/fixture/scratch")

            #expect(path == "/fixture/packages/swift-css")
            #expect(path.contains("checkouts") == false)
        }

        @Test
        func `an edited dependency compiles from its working copy`() {
            // The retired workflow still has live records, and its whole point
            // is that the working copy is compiled rather than the checkout it
            // displaced — so the superseded revision must not steer the result.
            let superseded = Package.Resolution.Dependency.Superseded(
                reference: Self.reference(
                    "swift-parser-primitives",
                    kind: .localSourceControl,
                    location: "/fixture/worktrees/swift-parser-primitives"
                ),
                checkout: .init(revision: "aaa111", pin: .branch("main")),
                subpath: "swift-parser-primitives"
            )
            let dependency = Package.Resolution.Dependency(
                reference: Self.reference(
                    "swift-parser-primitives",
                    kind: .localSourceControl,
                    location: "/fixture/worktrees/swift-parser-primitives"
                ),
                state: .edited(
                    path: "/fixture/edited/swift-parser-primitives",
                    basedOn: superseded
                ),
                subpath: "swift-parser-primitives"
            )

            let path = Package.Manager().materialized
                .source(of: dependency, at: "/fixture/root")

            #expect(path == "/fixture/edited/swift-parser-primitives")
            #expect(path.contains("checkouts") == false)
            // The displaced checkout's revision is still readable, and still
            // does not describe what is being compiled.
            #expect(dependency.state.superseded?.checkout.revision == "aaa111")
            #expect(dependency.revision == nil)
        }
    }
}
