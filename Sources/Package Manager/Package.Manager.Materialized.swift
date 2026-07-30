public import SPM_Standard

extension Package.Manager {
    /// Derivations of the source trees a build actually compiles.
    ///
    /// Reached as ``Package/Manager/materialized``, so the call site reads
    /// `manager.materialized.source(of:at:)` rather than carrying a compound
    /// method name.
    ///
    /// Stateless: every derivation here is a pure function of a resolved
    /// dependency and a scratch path. Nothing in this type reads the
    /// filesystem, and nothing asserts that a derived path exists — "derived"
    /// and "present" are different claims, and a caller verifying a
    /// materialization must check presence separately. A path that was derived
    /// correctly but is absent is itself a finding, and merging the two would
    /// hide it.
    public struct Materialized: Swift.Sendable {
        internal init() {}
    }
}

extension Package.Manager {
    /// Derivations of the source trees a build actually compiles.
    public var materialized: Materialized { .init() }
}

extension Package.Manager.Materialized {
    /// The source tree the build compiles for a resolved dependency.
    ///
    /// **Derived, never assumed, and never equated with a reference
    /// location.** For a managed checkout the compiled tree lives under the
    /// scratch directory; the reference's own location is where SwiftPM
    /// *fetched from*, and under an active mirror that is a mutable worktree
    /// which routinely diverges from what was compiled. Reporting a mirror
    /// target as the compiled source is the specific error this operation
    /// exists to prevent.
    ///
    /// | resolved state | compiled tree |
    /// |---|---|
    /// | `sourceControlCheckout` | `<scratch>/checkouts/<subpath>` |
    /// | `fileSystem` | the recorded path — used in place, no checkout |
    /// | `edited` | the recorded path — the working copy replacing the checkout |
    ///
    /// - Parameters:
    ///   - dependency: The resolved dependency record.
    ///   - directory: The package directory.
    ///   - scratch: The scratch directory SwiftPM used. Defaults as in
    ///     ``Package/Manager/resolution(at:scratch:)``.
    /// - Returns: The path of the source tree the build compiles.
    public func source(
        of dependency: Package.Resolution.Dependency,
        at directory: Swift.String,
        scratch: Swift.String? = nil
    ) -> Swift.String {
        switch dependency.state {
        case .sourceControlCheckout:
            "\(scratch ?? "\(directory)/.build")/checkouts/\(dependency.subpath)"

        case .fileSystem(let path), .edited(let path, _):
            path
        }
    }
}
