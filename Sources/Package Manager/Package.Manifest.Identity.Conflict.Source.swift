extension Package.Manifest.Identity.Conflict {
    /// The root document that contributed a source-control location.
    public enum Source: Swift.Sendable, Swift.Hashable {
        case manifest
        case pin
    }
}
