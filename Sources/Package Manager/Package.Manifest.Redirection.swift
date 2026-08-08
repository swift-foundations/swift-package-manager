public import SPM_Standard

extension Package.Manifest {
    /// Redirecting a URL-declared dependency to a **local mutable source**
    /// at an existing checkout, and undoing it byte-for-byte.
    ///
    /// The mechanism is generated `.package(path:)` composition: the manifest's
    /// url-form clause is rewritten in place to a path-form clause, and the
    /// declared clause is captured **verbatim** so ``restore(_:planned:declared:)``
    /// can return it byte-for-byte. A composed manifest therefore carries a
    /// machine-local absolute path. That is a virtue, not a bug, as long as it
    /// stays local — off-machine it fails *loudly* at resolution rather than
    /// silently substituting a wrong source — but it means a composed manifest
    /// must never be committed; callers own surfacing that warning.
    ///
    /// This is a pure source-to-source transformation. Deciding *which* local
    /// checkout a dependency redirects to — org layout, checkout discovery,
    /// ledgering the reversal — stays with the caller.
    public enum Redirection {}
}

extension Package.Manifest.Redirection {
    /// Rewrites the url-form clause declaring `url` in `source` to a
    /// `.package(path:)` clause pointing at `path`.
    ///
    /// The clause is located by SwiftPM package identity derived from `url`
    /// (see ``Package/Manifest/Clause/identity(ofURL:)``), so a declaration
    /// that omits a trailing `.git` or differs in case still matches.
    ///
    /// - Parameters:
    ///   - source: The consumer manifest source to rewrite.
    ///   - url: The dependency's declared source-control URL.
    ///   - path: The local checkout the dependency redirects to. Written into
    ///     the manifest exactly as given; pass an absolute path so a leaked
    ///     composed manifest fails loudly off-machine.
    /// - Returns: The rewritten source together with the declared clause
    ///   captured verbatim and the planned clause that replaced it.
    /// - Throws: ``Error/dependencyNotDeclaredByURL(identity:)`` when no
    ///   url-form clause in `source` declares the dependency.
    public static func redirect(
        _ source: Swift.String,
        dependency url: Swift.String,
        to path: Swift.String
    ) throws(Error) -> Rewrite {
        let identity = Package.Manifest.Clause.identity(ofURL: url)
        guard let clause = Package.Manifest.Clause.url(identity: identity, in: source) else {
            throw .dependencyNotDeclaredByURL(identity: identity)
        }
        let planned = ".package(path: \"\(path)\")"
        return Rewrite(
            source: clause.replacing(with: planned, in: source),
            declared: clause.text,
            planned: planned
        )
    }

    /// Restores `source` to its declared url-form clause **byte-for-byte**:
    /// locates the clause whose text equals `planned` and replaces it with
    /// `declared` verbatim.
    ///
    /// - Parameters:
    ///   - source: The composed manifest source to restore.
    ///   - planned: The exact path-form clause a prior
    ///     ``redirect(_:dependency:to:)`` wrote.
    ///   - declared: The exact url-form clause it captured.
    /// - Returns: The restored manifest source.
    /// - Throws: ``Error/composedClauseAbsent(planned:)`` when `source` no
    ///   longer contains `planned` — it may have been hand-edited or already
    ///   restored, and guessing would be worse than refusing.
    public static func restore(
        _ source: Swift.String,
        planned: Swift.String,
        declared: Swift.String
    ) throws(Error) -> Swift.String {
        let located = Package.Manifest.Clause.all(in: source).first { $0.text == planned }
        guard let clause = located else {
            throw .composedClauseAbsent(planned: planned)
        }
        return clause.replacing(with: declared, in: source)
    }
}
