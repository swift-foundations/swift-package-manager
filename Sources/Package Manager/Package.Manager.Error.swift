extension Package.Manager {

    public enum Error: Swift.Error, Sendable, Equatable {

        case execution

        case command(termination: Termination, stderr: [UInt8])

        case output

        case manifest

        case state

        case locked(directory: Swift.String)

        case timedOut(directory: Swift.String)
    }
}
