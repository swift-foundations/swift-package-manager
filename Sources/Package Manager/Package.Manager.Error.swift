extension Package.Manager {
    /// A failure of an operation backed by an installed SwiftPM toolchain.
    public enum Error: Swift.Error, Sendable, Equatable {
        /// SwiftPM could not be spawned at all.
        case execution

        /// SwiftPM ran and terminated unsuccessfully. `stderr` is preserved
        /// exactly as captured, undecoded.
        case command(termination: Termination, stderr: [UInt8])

        /// SwiftPM terminated successfully but produced no usable stdout.
        case output

        /// SwiftPM's manifest output could not be interpreted.
        ///
        /// Covers both shapes this package reads: the manifest that
        /// ``Package/Manager/manifest(at:)`` returns and the evaluation that
        /// ``Package/Manager/evaluation(at:)`` returns, and both stages of
        /// reading either — output that is not well-formed JSON, and
        /// well-formed JSON that does not match the expected shape.
        ///
        /// Deliberately does not distinguish those cases. A caller cannot act
        /// differently on them, and splitting the enum for wording alone would
        /// break every existing switch for no behavioural gain.
        case manifest
    }
}
