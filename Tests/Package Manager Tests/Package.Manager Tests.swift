import Testing
import Package_Manager

@Test
func `manifest invokes SwiftPM and decodes the standard model`() throws {
    let manifest = try Package.Manager().manifest(at: "Tests/Fixtures/Fixture")
    #expect(manifest.name == "fixture")
    #expect(manifest.dependencies.isEmpty)
}
