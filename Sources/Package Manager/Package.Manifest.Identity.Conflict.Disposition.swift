extension Package.Manifest.Identity.Conflict {
    /// Whether a divergence is load-fatal or only a stale resolved pin.
    public enum Disposition: Swift.Sendable, Swift.Hashable {
        case fatal
        case stalePin
    }
}
