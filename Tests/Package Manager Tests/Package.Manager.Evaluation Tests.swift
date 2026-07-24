import Package_Manager
import Testing

/// State of the machine the tests are running on, read by the condition trait
/// on `Integration`. Lives outside that suite because a suite's own trait
/// cannot reference the type it decorates.
private enum Machine {}

extension Machine {

    /// A real package with real dependencies, vendored inside this package's
    /// checkouts. Relative, so no maintainer path appears here; it is
    /// machine-specific only in that the checkout must exist.
    static var checkout: Swift.String { ".build/checkouts/swift-spm-standard" }

    /// Whether this machine's mirrors redirect any dependency of ``checkout``
    /// to a local path.
    ///
    /// Read before `Integration` runs, so absence is a skip rather than a
    /// failure.
    static var substitutes: Bool {
        do throws(Package.Manager.Error) {
            let evaluation = try Package.Manager().evaluation(at: checkout)
            return evaluation.dependencies.contains { dependency in
                guard case .sourceControl(_, .local, _) = dependency.source
                else { return false }
                return true
            }
        } catch {
            // Discarded deliberately: a manager failure here means the
            // observation cannot be made on this machine, which is a skip.
            // The deterministic suite covers operational failure as a failure.
            return false
        }
    }
}

extension Package.Manager {
    /// Tests for ``Package/Manager/evaluation(at:)``.
    ///
    /// `Unit` runs entirely against fixtures in this repository: a package and
    /// a sibling it reaches by a RELATIVE path. Nothing there consults mirror
    /// configuration, so the results are identical on any machine.
    ///
    /// `Integration` is NOT portable — see the note on that suite.
    @Suite
    struct Test {

        // MARK: - Deterministic, fixture-only

        @Suite
        struct Unit {

            @Test
            func `evaluation returns the package name`() throws {
                let evaluation = try Package.Manager()
                    .evaluation(at: "Tests/Fixtures/Composed")
                #expect(evaluation.name == "composed")
            }

            @Test
            func `evaluation preserves the tools version`() throws {
                let evaluation = try Package.Manager()
                    .evaluation(at: "Tests/Fixtures/Composed")
                #expect(Swift.String(describing: evaluation.toolsVersion) == "6.3.0")
            }

            @Test
            func `evaluation reports the declared dependency`() throws {
                let evaluation = try Package.Manager()
                    .evaluation(at: "Tests/Fixtures/Composed")
                #expect(evaluation.dependencies.isEmpty == false)
                #expect(evaluation.dependencies.count == 1)
                #expect(evaluation.dependencies[0].identity == "dependency")
            }

            @Test
            func `a genuine path dependency stays a filesystem source`() throws {
                let evaluation = try Package.Manager()
                    .evaluation(at: "Tests/Fixtures/Composed")
                let dependency = try #require(evaluation.dependencies.first)
                guard case .fileSystem(let identity, let path) = dependency.source else {
                    Issue.record("Expected .fileSystem, got \(dependency.source)")
                    return
                }
                #expect(identity == "dependency")
                // The absolute path is machine-specific; only its tail is
                // asserted so this stays portable.
                #expect(path.hasSuffix("Tests/Fixtures/Dependency"))
            }

            @Test
            func `no requirement is invented for a path dependency`() throws {
                // `dump-package` emits no `requirement` key for a fileSystem
                // record. Synthesising one would be a fabricated fact.
                let evaluation = try Package.Manager()
                    .evaluation(at: "Tests/Fixtures/Composed")
                let dependency = try #require(evaluation.dependencies.first)
                #expect(dependency.requirement == nil)
            }

            @Test
            func `products survive the evaluation`() throws {
                let evaluation = try Package.Manager()
                    .evaluation(at: "Tests/Fixtures/Composed")
                #expect(evaluation.products.count == 2)
                #expect(evaluation.products.map(\.name) == ["Composed", "Composed Helper"])
            }

            @Test
            func `targets survive the evaluation`() throws {
                let evaluation = try Package.Manager()
                    .evaluation(at: "Tests/Fixtures/Composed")
                #expect(evaluation.targets.count == 2)
                #expect(evaluation.targets.map(\.name) == ["Composed", "Composed Helper"])
            }

            @Test
            func `platforms survive the evaluation`() throws {
                let evaluation = try Package.Manager()
                    .evaluation(at: "Tests/Fixtures/Composed")
                let platforms = try #require(evaluation.platforms)
                #expect(platforms.count == 2)
                #expect(platforms.map(\.platform) == [.macOS, .iOS])
                #expect(platforms.map(\.version) == ["13.0", "16.0"])
            }

            @Test
            func `dependency products are back-filled from target edges`() throws {
                // `Composed` depends on exactly one of the dependency's two
                // products. The back-fill must report that one — not both,
                // which would over-report, and not none, which is what the
                // manifest operation yields.
                let evaluation = try Package.Manager()
                    .evaluation(at: "Tests/Fixtures/Composed")
                let dependency = try #require(evaluation.dependencies.first)
                #expect(dependency.products == ["Dependency Core"])
            }

            @Test
            func `an unusable package directory fails as an operational error`() throws {
                #expect(throws: Package.Manager.Error.self) {
                    try Package.Manager()
                        .evaluation(at: "Tests/Fixtures/Does Not Exist")
                }
            }

            @Test
            func `an unsuccessful termination preserves stderr`() throws {
                do throws(Package.Manager.Error) {
                    _ = try Package.Manager().evaluation(at: "Tests/Fixtures/Broken")
                    Issue.record("Expected the broken fixture to fail")
                } catch {
                    guard case .command(let termination, let stderr) = error else {
                        Issue.record("Expected .command, got \(error)")
                        return
                    }
                    #expect(termination != .exited(code: 0))
                    #expect(stderr.isEmpty == false)
                    let text = Swift.String(decoding: stderr, as: UTF8.self)
                    #expect(text.contains("Broken"))
                }
            }

            @Test
            func `manifest keeps its existing behaviour after the refactor`() throws {
                // Same operation, same results, now sharing the invocation
                // with `evaluation(at:)`.
                let manager = Package.Manager()

                let bare = try manager.manifest(at: "Tests/Fixtures/Fixture")
                #expect(bare.name == "fixture")
                #expect(bare.dependencies.isEmpty)

                let composed = try manager.manifest(at: "Tests/Fixtures/Composed")
                #expect(composed.name == "composed")
                #expect(composed.dependencies.count == 1)
            }

            @Test
            func `manifest and evaluation agree on what they both report`() throws {
                let manager = Package.Manager()
                let manifest = try manager.manifest(at: "Tests/Fixtures/Composed")
                let evaluation = try manager.evaluation(at: "Tests/Fixtures/Composed")
                #expect(manifest.name == evaluation.name)
                #expect(manifest.toolsVersion == evaluation.toolsVersion)
                #expect(manifest.dependencies.count == evaluation.dependencies.count)
            }
        }

        // MARK: - Current-machine observation (NOT portable)

        /// Observes THIS machine's mirror configuration. Not portable, and not
        /// an owner-package unit test.
        ///
        /// A mirror map redirects canonical URLs to local checkouts, so
        /// `dump-package` reports those dependencies as `sourceControl` with a
        /// `local` location. No fixture in this repository can produce that
        /// shape — it is a property of the machine's configuration rather than
        /// of any package — so this suite is an observation of local state.
        ///
        /// When no such dependency exists the suite is SKIPPED by a condition
        /// trait, which is Swift Testing's supported mechanism. It does not
        /// record an issue and does not fail.
        ///
        /// ## Why it reads a checkout rather than this package
        ///
        /// `evaluation(at:)` spawns SwiftPM, and SwiftPM takes an exclusive
        /// lock on the target package's `.build`. Pointing this at `"."` makes
        /// the test process wait on a lock the *test runner itself* holds —
        /// SwiftPM reports `Another instance of SwiftPM (PID: …) is already
        /// running using '…/.build', waiting until that process has finished
        /// execution` and both sides wait forever. Verified empirically. A
        /// vendored checkout has its own `.build`, so no lock is shared.
        @Suite(
            .enabled(
                if: Machine.substitutes,
                """
                No dependency of the observed checkout is mirror-substituted to \
                a local path on this machine.
                """
            )
        )
        struct Integration {

            @Test
            func `a mirror-substituted dependency stays source control with a local location`()
                throws
            {
                let evaluation = try Package.Manager().evaluation(at: Machine.checkout)

                var observed = 0
                for dependency in evaluation.dependencies {
                    guard
                        case .sourceControl(let identity, let location, _) =
                            dependency.source
                    else { continue }
                    guard case .local(let path) = location else { continue }
                    observed += 1

                    // Reported as source control, NOT collapsed into a
                    // filesystem dependency.
                    if case .fileSystem = dependency.source {
                        Issue.record("Mirror-substituted source became .fileSystem")
                    }
                    // The requirement survives the substitution. A filesystem
                    // dependency would carry none.
                    #expect(dependency.requirement != nil)
                    // A real path — not empty, and not a fabricated `file://`.
                    #expect(path.isEmpty == false)
                    #expect(path.hasPrefix("/"))
                    #expect(path.hasPrefix("file://") == false)
                    #expect(Swift.String(describing: identity).isEmpty == false)
                }

                // The condition trait guarantees at least one, so a change to
                // that trait cannot let this pass vacuously.
                #expect(observed > 0)
            }
        }
    }
}
