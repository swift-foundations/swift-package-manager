public import SPM_Standard

extension Package {
    /// Foundation-free operations supplied by an installed SwiftPM toolchain.
    public struct Manager: Sendable {
        public let executable: Swift.String

        public init(executable: Swift.String = Package.Manager.launcher) {
            self.executable = executable
        }
    }
}

extension Package.Manager {
    /// The launcher spawned when the caller does not name a SwiftPM binary.
    ///
    /// Neither `posix_spawn` nor `CreateProcessW` searches `PATH` when it is
    /// handed an executable to run, so a bare `swift` cannot be the default:
    /// the spawn would fail before SwiftPM ever ran. Each platform instead
    /// spawns the launcher it ships at a fixed absolute location and lets
    /// that launcher resolve `swift` on `PATH` — `/usr/bin/env` on POSIX,
    /// the command interpreter on Windows.
    public static var launcher: Swift.String {
        #if os(Windows)
            "C:\\Windows\\System32\\cmd.exe"
        #else
            "/usr/bin/env"
        #endif
    }

    /// The arguments that precede a `swift` sub-command for this instance.
    ///
    /// Empty when the caller named a SwiftPM binary directly — its arguments
    /// are the sub-command itself. When the platform launcher is in use, the
    /// prefix is whatever that launcher needs in order to run `swift`.
    ///
    /// One property rather than a comparison at each call site, so the
    /// reading and the state-changing operations cannot drift in how they
    /// invoke the toolchain.
    internal var launcherPrefix: [Swift.String] {
        guard executable == Package.Manager.launcher else { return [] }
        #if os(Windows)
            return ["/c", "swift"]
        #else
            return ["swift"]
        #endif
    }
}
