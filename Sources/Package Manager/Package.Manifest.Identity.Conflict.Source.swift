extension Package.Manifest.Identity.Conflict {

    public enum Source: Swift.Sendable, Swift.Hashable {
        case manifest
        case pin
    }
}
