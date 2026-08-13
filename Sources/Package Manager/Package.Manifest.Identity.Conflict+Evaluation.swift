extension Package.Manifest.Identity.Conflict {
    /// Whether `name` is a root package manifest recognized by SwiftPM's
    /// versioned-manifest convention.
    public static func isRootManifest(_ name: Swift.String) -> Swift.Bool {
        guard name.hasPrefix("Package"), name.hasSuffix(".swift") else { return false }
        let middle = name.dropFirst("Package".count).dropLast(".swift".count)
        if middle.isEmpty { return true }
        guard middle.hasPrefix("@swift-") else { return false }
        let version = middle.dropFirst("@swift-".count)
        return !version.isEmpty && version.allSatisfy { $0.isNumber || $0 == "." }
    }

    /// URL entries declared by `.package(url: …)` clauses in one root manifest.
    public static func entries(
        in manifest: Swift.String,
        document: Swift.String
    ) -> [Entry] {
        Package.Manifest.Clause.all(in: manifest).compactMap { clause in
            clause.declaredURL.map {
                Entry(url: $0, document: document, source: .manifest)
            }
        }
    }

    /// Distinct-location findings, sorted by identity and location.
    ///
    /// Two manifest locations for one identity are load-fatal. A manifest
    /// location that only disagrees with `Package.resolved` is stale state:
    /// re-resolution rewrites the pin, so callers warn without refusing.
    public static func findings(in entries: [Entry]) -> [Finding] {
        let grouped = Swift.Dictionary(grouping: entries, by: \.identity)
        return grouped.keys.sorted().compactMap { identity in
            guard let observed = grouped[identity] else { return nil }
            let locations = Swift.Dictionary(grouping: observed, by: \.location)
            guard locations.count > 1 else { return nil }
            let manifestLocations = locations.values.filter { entries in
                entries.contains { $0.source == .manifest }
            }
            let disposition: Disposition = manifestLocations.count > 1 ? .fatal : .stalePin
            let ordered = observed.sorted {
                ($0.location, $0.document) < ($1.location, $1.document)
            }
            return Finding(identity: identity, entries: ordered, disposition: disposition)
        }
    }

    /// The canonical location SwiftPM compares for source-control identity.
    /// Scheme and SCP-style user prefixes, trailing slashes, `.git`, and case
    /// do not distinguish locations.
    public static func canonical(_ url: Swift.String) -> Swift.String {
        var value = url[...]
        while value.first?.isWhitespace == true { value = value.dropFirst() }
        while value.last?.isWhitespace == true { value = value.dropLast() }
        var location = Swift.String(value).lowercased()

        if let scheme = location.firstIndex(of: ":"),
            location[location.index(after: scheme)...].hasPrefix("//")
        {
            location = Swift.String(location[location.index(scheme, offsetBy: 3)...])
        } else if let at = location.firstIndex(of: "@"),
            let colon = location[location.index(after: at)...].firstIndex(of: ":")
        {
            let host = location[location.index(after: at)..<colon]
            let path = location[location.index(after: colon)...]
            location = "\(host)/\(path)"
        }

        while location.last == "/" { location.removeLast() }
        if location.hasSuffix(".git") { location.removeLast(4) }
        return location
    }
}
