private import JSON

extension Package.Manifest.Identity.Conflict {
    /// Source-control locations recorded by a SwiftPM `Package.resolved` file.
    ///
    /// Missing, malformed, and non-string pin locations contribute no entries,
    /// matching SwiftPM's ability to regenerate resolved state from manifests.
    public static func entries(
        inResolved source: Swift.String,
        document: Swift.String = "Package.resolved"
    ) -> [Entry] {
        let json: JSON
        do throws(JSON.Error) {
            json = try JSON.parse(source)
        } catch {
            return []
        }
        guard let pins = json["pins"].array else { return [] }
        return pins.compactMap { pin in
            let location = Swift.String(pin["location"])
            guard !location.isEmpty else { return nil }
            return Entry(url: location, document: document, source: .pin)
        }
    }
}
