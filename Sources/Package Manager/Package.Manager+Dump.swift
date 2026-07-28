internal import JSON
internal import Process
internal import SPM_Standard

extension Package.Manager {
    /// Runs `swift package dump-package` at `directory` and parses its output.
    ///
    /// The single owner of the SwiftPM invocation: executable selection,
    /// arguments, working directory, stdout and stderr capture, termination
    /// validation, missing-output validation, and JSON parsing. Both
    /// ``manifest(at:)`` and ``evaluation(at:)`` read the same bytes through
    /// here, so the two operations cannot drift in how they spawn SwiftPM or
    /// in which failures they report.
    ///
    /// Parsing lives here rather than in each caller because both callers
    /// need a parsed tree; interpreting that tree is what differs between
    /// them.
    ///
    /// - Important: SwiftPM takes an exclusive lock on the target package's
    ///   `.build`, and waits indefinitely for it rather than failing. A caller
    ///   already holding that lock for the same directory — most easily, a
    ///   test process invoking this on the package under test — deadlocks:
    ///   SwiftPM reports `Another instance of SwiftPM (PID: …) is already
    ///   running using '…/.build', waiting until that process has finished
    ///   execution`, and neither side can proceed. This operation cannot
    ///   detect that condition; the caller must not point it at a package it
    ///   is concurrently building.
    internal func dump(at directory: Swift.String) throws(Error) -> JSON {
        let output: Process.Output
        do throws(Process.Error) {
            output = try Process.Spawn.run(
                .init(
                    executable: executable,
                    arguments: executable == "/usr/bin/env"
                        ? ["swift", "package", "dump-package"]
                        : ["package", "dump-package"],
                    stdout: .pipe,
                    stderr: .pipe,
                    workingDirectory: directory
                )
            )
        } catch {
            throw .execution
        }

        guard output.status == .exited(code: 0) else {
            throw .command(
                termination: termination(output.status),
                stderr: output.stderr ?? []
            )
        }
        guard let bytes = output.stdout else {
            throw .output
        }

        do throws(JSON.Error) {
            return try JSON.parse(Swift.String(decoding: bytes, as: UTF8.self))
        } catch {
            throw .manifest
        }
    }

    /// Maps a spawn status onto this package's own termination model.
    ///
    /// `internal` rather than `private` so the state-changing operations in
    /// `Package.Manager+Edit.swift` report failures in the same shape as the
    /// reading operations here. Two mappings would be two chances to drift.
    internal func termination(_ status: Process.Status) -> Termination {
        switch status {
        case .exited(let code): .exited(code: code)
        case .signaled(let signal): .signaled(signal: signal)
        case .stopped(let signal): .stopped(signal: signal)
        }
    }
}
