extension Package.Manager {
    public enum Termination: Sendable, Equatable {
        case exited(code: Swift.Int32)
        case signaled(signal: Swift.Int32)
        case stopped(signal: Swift.Int32)
    }
}
