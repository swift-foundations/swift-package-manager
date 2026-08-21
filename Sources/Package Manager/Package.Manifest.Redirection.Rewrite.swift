public import SPM_Standard

extension Package.Manifest.Redirection {

    public struct Rewrite: Swift.Sendable, Swift.Equatable {

        public let source: Swift.String

        public let declared: Swift.String

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
