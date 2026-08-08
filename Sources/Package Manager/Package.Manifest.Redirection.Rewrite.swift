public import SPM_Standard

extension Package.Manifest.Redirection {
    /// The result of one ``Package/Manifest/Redirection/redirect(_:dependency:to:)``:
    /// the rewritten manifest source plus the exact clause texts a
    /// byte-for-byte restore needs.
    ///
    /// `declared` and `planned` are the reversal record. A caller that
    /// persists them (in whatever ledger it owns) can restore the manifest
    /// verbatim later with ``Package/Manifest/Redirection/restore(_:planned:declared:)``.
    public struct Rewrite: Swift.Sendable, Swift.Equatable {
        /// The manifest source with the url-form clause replaced by `planned`.
        public let source: Swift.String

        /// The url-form clause that was replaced, captured verbatim.
        public let declared: Swift.String

        /// The path-form clause that replaced it.
        public let planned: Swift.String

        public init(
            source: Swift.String,
            declared: Swift.String,
            planned: Swift.String
        ) {
            self.source = source
            self.declared = declared
            self.planned = planned
        }
    }
}
