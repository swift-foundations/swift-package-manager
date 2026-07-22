extension Package.Manager {
    public enum Error: Swift.Error, Sendable, Equatable {
        case execution
        case command(termination: Termination, stderr: [UInt8])
        case output
        case manifest
    }
}
