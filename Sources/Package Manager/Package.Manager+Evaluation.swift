private import JSON
public import SPM_Standard

extension Package.Manager {
    /// Evaluates `swift package dump-package` at a package directory, keeping
    /// everything the manifest output carries.
    ///
    /// The sibling of ``manifest(at:)``, and the one to prefer when the caller
    /// needs more than a package's name, tools version, and dependency list.
    /// ``Package/Manifest/Evaluation`` additionally preserves `products`,
    /// `targets`, `platforms`, per-dependency traits, and the
    /// dependency-product back-fill derived from target dependency edges.
    ///
    /// It also reads a dependency's source honestly. A dependency whose
    /// canonical URL is mirror-substituted to a local directory arrives as
    /// `sourceControl` with a `local` location; this operation reports it that
    /// way rather than collapsing it into a filesystem dependency, inventing a
    /// `file://` spelling, or recovering the declared URL. Distinguishing what
    /// SwiftPM actually evaluated from what a manifest declared is the reason
    /// this operation exists.
    ///
    /// Decoding runs through `swift-json`'s Foundation-free `Swift.Decoder`;
    /// no Foundation type participates.
    ///
    /// - Important: Spawns SwiftPM, which takes an exclusive lock on
    ///   `directory`'s `.build` and waits indefinitely for it. Do not call
    ///   this on a package the calling process is concurrently building —
    ///   notably, a test must not evaluate the package it is running from.
    ///
    /// - Parameter directory: The package directory to evaluate.
    /// - Returns: The evaluated manifest.
    /// - Throws: ``Package/Manager/Error``.
    public func evaluation(
        at directory: Swift.String
    ) throws(Error) -> Package.Manifest.Evaluation {
        let json = try dump(at: directory)
        do throws(DecodingError) {
            return try json.decode(Package.Manifest.Evaluation.self)
        } catch {
            throw .manifest
        }
    }
}
