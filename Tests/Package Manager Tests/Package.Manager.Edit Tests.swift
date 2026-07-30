import Testing

@testable import Package_Manager

// These tests deliberately do **not** invoke `swift package edit` against a real
// package. Doing so would take SwiftPM's exclusive lock on that package's
// `.build` — the very contention these operations exist to survive — and a test
// that hangs when the machine is busy is worse than no test. What is covered
// here is the classification logic, which is where the judgement lives; the
// invocation itself is the same spawn path `dump(at:)` already exercises.

@Suite struct `Edit lock classification` {}

extension `Edit lock classification` {
    private func bytes(_ text: Swift.String) -> [UInt8] { Array(text.utf8) }

    @Test
    func `SwiftPM's waiting notice is recognised`() {
        // The real message, with a representative PID and path. Only the stable
        // fragment is matched, because the PID and path vary per run.
        let notice = """
            Another instance of SwiftPM (PID: 41234) is already running using \
            '/Users/someone/pkg/.build', waiting until that process has \
            finished execution
            """
        #expect(Package.Manager.waiting(onLockIn: bytes(notice)))
    }

    @Test
    func `an unrelated stderr is not mistaken for lock contention`() {
        // The failure this guards: attributing every slow run to the lock would
        // turn a guess into a diagnosis. Anything without the notice must
        // classify as a plain timeout.
        #expect(!Package.Manager.waiting(onLockIn: bytes("error: unable to resolve dependencies")))
        #expect(!Package.Manager.waiting(onLockIn: bytes("")))
        #expect(!Package.Manager.waiting(onLockIn: bytes("running")))
    }

    @Test
    func `a stderr shorter than the needle does not overrun`() {
        // The scan indexes `stderr[start + offset]`, so a buffer shorter than
        // the needle must be rejected before the loop rather than inside it.
        #expect(!Package.Manager.waiting(onLockIn: bytes("is alr")))
        #expect(!Package.Manager.waiting(onLockIn: []))
    }

    @Test
    func `the notice is found when it is not at the start`() {
        let stderr = "warning: something first\nAnother instance of SwiftPM (PID: 9) is already running using '/x/.build'"
        #expect(Package.Manager.waiting(onLockIn: bytes(stderr)))
    }

    @Test
    func `a near-miss prefix does not match`() {
        // A partial match that restarts mid-needle would report contention on
        // text that never contained the notice.
        #expect(!Package.Manager.waiting(onLockIn: bytes("is already runnin")))
        #expect(Package.Manager.waiting(onLockIn: bytes("is already runnin is already running using")))
    }
}
