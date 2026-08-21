import Testing

@testable import Package_Manager

private func bytes(_ text: Swift.String) -> [UInt8] { Array(text.utf8) }

@Suite struct `Edit lock classification` {
    @Suite struct Unit {}
    @Suite struct `Edge Case` {}
    @Suite struct Integration {}
}

extension `Edit lock classification`.Unit {
    @Test
    func `SwiftPM's waiting notice is recognised`() {

        let notice = """
            Another instance of SwiftPM (PID: 41234) is already running using \
            '/Users/someone/pkg/.build', waiting until that process has \
            finished execution
            """
        #expect(Package.Manager.waiting(onLockIn: bytes(notice)))
    }

    @Test
    func `an unrelated stderr is not mistaken for lock contention`() {

        #expect(!Package.Manager.waiting(onLockIn: bytes("error: unable to resolve dependencies")))
        #expect(!Package.Manager.waiting(onLockIn: bytes("")))
        #expect(!Package.Manager.waiting(onLockIn: bytes("running")))
    }

    @Test
    func `the notice is found when it is not at the start`() {
        let stderr =
            "warning: something first\nAnother instance of SwiftPM (PID: 9) is already running using '/x/.build'"
        #expect(Package.Manager.waiting(onLockIn: bytes(stderr)))
    }
}

extension `Edit lock classification`.`Edge Case` {
    @Test
    func `a stderr shorter than the needle does not overrun`() {

        #expect(!Package.Manager.waiting(onLockIn: bytes("is alr")))
        #expect(!Package.Manager.waiting(onLockIn: []))
    }

    @Test
    func `a near-miss prefix does not match`() {

        #expect(!Package.Manager.waiting(onLockIn: bytes("is already runnin")))
        #expect(
            Package.Manager.waiting(onLockIn: bytes("is already runnin is already running using"))
        )
    }
}
