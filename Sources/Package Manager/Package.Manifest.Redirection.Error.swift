public import SPM_Standard

extension Package.Manifest.Redirection {
    /// Why a redirection or its restore refused to rewrite the manifest.
    public enum Error: Swift.Error, Swift.Sendable, Swift.Equatable {
        /// No url-form `.package(url:)` clause in the source declares a
        /// dependency with this SwiftPM package identity; there is nothing
        /// to redirect.
        case dependencyNotDeclaredByURL(identity: Swift.String)

        /// The composed `.package(path:)` clause a prior redirect wrote is
        /// not present in the source — it may have been hand-edited or
        /// already restored. Refusing to guess beats a wrong rewrite.
        case composedClauseAbsent(planned: Swift.String)
    }
}
