extension Package.Manifest.Dependency {
    /// Typed source-control facts declared by one `.package(url: …)` call.
    public struct SourceControl: Swift.Sendable, Swift.Hashable {
        public let url: Swift.String
        public let branch: Swift.String?
        public let document: Swift.String

        public init(url: Swift.String, branch: Swift.String?, document: Swift.String) {
            self.url = url
            self.branch = branch
            self.document = document
        }
    }
}
