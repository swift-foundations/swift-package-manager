public import SPM_Standard

extension Package {
    /// Foundation-free operations supplied by an installed SwiftPM toolchain.
    public struct Manager: Sendable {
        public let executable: Swift.String

        public init(executable: Swift.String = "/usr/bin/env") {
            self.executable = executable
        }
    }
}
