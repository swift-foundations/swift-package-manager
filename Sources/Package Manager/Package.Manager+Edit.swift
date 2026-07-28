internal import Process

extension Package.Manager {
    /// Puts a dependency into SwiftPM's editable mode, pointing it at a
    /// checkout that already exists.
    ///
    /// `swift package edit <identity> --path <path>` redirects one resolved
    /// dependency to a local working copy **without touching `Package.swift`
    /// or `Package.resolved`**. It writes two things: a symlink at
    /// `<package>/Packages/<identity>`, and an `edited` entry in the scratch
    /// directory's `workspace-state.json` recording the absolute path and the
    /// checkout it superseded.
    ///
    /// - Important: **The dependency must already be resolvable.** `edit` places
    ///   an existing graph slot; it does not create one. Against an
    ///   unsatisfiable requirement, or with the remote unreachable and no warm
    ///   checkout, SwiftPM exits non-zero with the resolver's own error. That is
    ///   correct and is not softened here: an overlay can be *used* offline, but
    ///   not *applied* offline.
    ///
    /// - Important: **`swift package edit` accepts no `--scratch-path`.** Its
    ///   entire option set is `--revision`, `--branch`, and `--path`; supplying
    ///   a scratch redirect is a usage error (exit 64). Editable state is
    ///   therefore always written to the package's default `.build`, and a build
    ///   given a custom scratch path **cannot see it** — it resolves
    ///   canonically, exits zero, and says nothing. A caller that redirects
    ///   scratch for a build must not assume an overlay applies to it.
    ///
    /// - Parameters:
    ///   - identity: The package identity to redirect, as SwiftPM computed it.
    ///   - path: The existing checkout to compile in its place.
    ///   - directory: The package directory whose graph is being redirected.
    ///   - timeout: How long to let SwiftPM run before killing it and reporting
    ///     a named failure. See ``Package/Manager/Error/locked(directory:)``.
    /// - Throws: ``Package/Manager/Error``.
    public func edit(
        _ identity: Swift.String,
        path: Swift.String,
        at directory: Swift.String,
        timeout: Swift.Duration = .seconds(120)
    ) throws(Error) {
        try run(["package", "edit", identity, "--path", path], at: directory, timeout: timeout)
    }

    /// Returns a dependency from editable mode to its resolved source.
    ///
    /// The inverse of ``edit(_:path:at:timeout:)``, and a **complete** one: it
    /// removes the `Packages/` symlink, restores the `sourceControlCheckout`
    /// state, and re-creates the managed working copy, so the next build
    /// compiles canonical source again. The developer's own worktree at the
    /// edited path — including uncommitted work — is left untouched.
    ///
    /// - Important: SwiftPM exits non-zero when the dependency is not in edit
    ///   mode. That is worth surfacing rather than swallowing: a caller that
    ///   finds an editable symlink present *and* this call failing has detected
    ///   half-applied state, not a no-op.
    ///
    /// - Parameters:
    ///   - identity: The package identity to return to its resolved source.
    ///   - directory: The package directory whose graph is being restored.
    ///   - force: Return the dependency even when its working copy carries
    ///     uncommitted or unpushed changes. Off by default: the point of the
    ///     editable workflow is work that is not yet pushed, and discarding it
    ///     silently would be the worse failure.
    ///   - timeout: As ``edit(_:path:at:timeout:)``.
    /// - Throws: ``Package/Manager/Error``.
    public func unedit(
        _ identity: Swift.String,
        at directory: Swift.String,
        force: Swift.Bool = false,
        timeout: Swift.Duration = .seconds(120)
    ) throws(Error) {
        try run(
            force
                ? ["package", "unedit", "--force", identity]
                : ["package", "unedit", identity],
            at: directory,
            timeout: timeout
        )
    }
}

extension Package.Manager {
    /// Runs a state-changing SwiftPM subcommand at `directory` under a deadline.
    ///
    /// ## Why these commands are always run under a timeout
    ///
    /// SwiftPM takes an **exclusive lock on the target package's `.build`**, and
    /// when it cannot acquire it, prints
    /// `Another instance of SwiftPM (PID: …) is already running using '…/.build',
    /// waiting until that process has finished execution` — and then **waits
    /// indefinitely**. It does not time out and it does not fail.
    ///
    /// An unbounded call is therefore worse than a failing one: a hang has no
    /// exit status, no diagnostic, and nothing a caller can report or act on. On
    /// a machine running a fleet-wide sweep it is also the *expected* case, not
    /// an edge one. A caller degrading from a fast path to a slow one has to be
    /// able to say why it degraded, and a process that never returns says
    /// nothing at all.
    ///
    /// ## How expiry is classified
    ///
    /// On expiry the child is `SIGKILL`ed and the run reports
    /// ``Process/Status/signaled(signal:)``, with whatever stderr was drained
    /// before the kill preserved. Because SwiftPM prints its waiting notice
    /// *before* it begins waiting, that notice is in the captured stderr, and
    /// the two outcomes can be told apart:
    ///
    /// - notice present → ``Package/Manager/Error/locked(directory:)``, which
    ///   names the actual cause;
    /// - notice absent → ``Package/Manager/Error/timedOut(directory:)``, an
    ///   honest "it did not finish", because attributing every slow run to the
    ///   lock would be a guess dressed as a diagnosis.
    ///
    /// **The discrimination reads a message SwiftPM owns and may reword.** That
    /// is a deliberate, bounded risk: if the wording changes, a locked run
    /// degrades from ``locked`` to ``timedOut``. It degrades to a *less
    /// specific loud failure*, never to silence and never to a false success —
    /// which is the property worth preserving. The timeout itself does not
    /// depend on the message at all.
    private func run(
        _ arguments: [Swift.String],
        at directory: Swift.String,
        timeout: Swift.Duration
    ) throws(Error) {
        let output: Process.Output
        do throws(Process.Error) {
            output = try Process.Spawn.run(
                .init(
                    executable: executable,
                    arguments: executable == "/usr/bin/env"
                        ? ["swift"] + arguments
                        : arguments,
                    stdout: .pipe,
                    stderr: .pipe,
                    workingDirectory: directory,
                    timeout: timeout
                )
            )
        } catch {
            throw .execution
        }

        if case .signaled = output.status {
            let stderr = output.stderr ?? []
            throw Self.waiting(onLockIn: stderr)
                ? .locked(directory: directory)
                : .timedOut(directory: directory)
        }

        guard output.status == .exited(code: 0) else {
            throw .command(
                termination: termination(output.status),
                stderr: output.stderr ?? []
            )
        }
    }

    /// Whether captured stderr carries SwiftPM's build-lock waiting notice.
    ///
    /// Matched on the stable fragment of the message rather than the whole
    /// sentence, which carries a PID and a path. Byte-wise, so no decoding of
    /// output whose encoding this package does not control.
    ///
    /// `internal` rather than `private` so the classification can be tested
    /// directly. Testing it through a real invocation would mean taking the
    /// build lock this exists to detect, and a test that hangs on a busy
    /// machine is worse than no test.
    internal static func waiting(onLockIn stderr: [UInt8]) -> Swift.Bool {
        let needle = Array("is already running using".utf8)
        guard stderr.count >= needle.count else { return false }
        for start in 0...(stderr.count - needle.count) {
            var matched = true
            for offset in needle.indices where stderr[start + offset] != needle[offset] {
                matched = false
                break
            }
            if matched { return true }
        }
        return false
    }
}
