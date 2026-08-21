extension Package.Manifest.Identity.Conflict {

    public enum Disposition: Swift.Sendable, Swift.Hashable {
        case fatal
        case stalePin
    }
}
