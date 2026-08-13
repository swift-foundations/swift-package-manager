extension Package.Manifest.Identity.Conflict {
    /// All distinct locations observed for one conflicting package identity.
    public struct Finding: Swift.Sendable, Swift.Equatable {
        public let identity: Swift.String
        public let entries: [Entry]
        public let disposition: Disposition

        public init(identity: Swift.String, entries: [Entry], disposition: Disposition) {
            self.identity = identity
            self.entries = entries
            self.disposition = disposition
        }
    }
}
