public import SPM_Standard

extension Package.Manifest.Redirection {

    public enum Error: Swift.Error, Swift.Sendable, Swift.Equatable {

        case dependencyNotDeclaredByURL(identity: Swift.String)

        case composedClauseAbsent(planned: Swift.String)
    }
}
