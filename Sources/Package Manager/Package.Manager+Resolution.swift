internal import File_System
private import JSON
public import SPM_Standard

extension Package.Manager {
    /// Reads SwiftPM's resolved state for a package.
    ///
    /// Unlike ``manifest(at:)`` and ``evaluation(at:)``, this spawns nothing.
    /// Resolved state is a file SwiftPM already wrote, so reading it is an
    /// observation rather than an invocation — which also means it is free of
    /// the `.build` locking hazard those two carry.
    ///
    /// - Parameters:
    ///   - directory: The package directory.
    ///   - scratch: The scratch directory SwiftPM used. Defaults to
    ///     `<directory>/.build`, which is where an unredirected SwiftPM writes
    ///     and where the machine coordinator's package actions leave it — the
    ///     coordinator passes no scratch redirect and runs with the package as
    ///     the working directory. Supply it explicitly for any build that was
    ///     redirected, rather than relying on that default holding.
    /// - Returns: The resolved state.
    /// - Throws: ``Package/Manager/Error``.
    public func resolution(
        at directory: Swift.String,
        scratch: Swift.String? = nil
    ) throws(Error) -> Package.Resolution {
        let path = "\(scratch ?? "\(directory)/.build")/workspace-state.json"

        let location: File.Path
        do throws(File.Path.Error) {
            location = try File.Path(path)
        } catch {
            throw .state
        }

        let bytes: [Byte]
        // The closure is non-throwing, so `E` infers as `Never` and the
        // closure arm of the thrown `Either` is statically uninhabited.
        do throws(Either<File.System.Read.Full.Error, Never>) {
            bytes = try File(location).read.full { span in
                var storage = [Byte]()
                storage.reserveCapacity(span.count)
                // `span.indices` rather than a `0..<count` counter: the intent
                // is "every element of this span", and the counter is only the
                // mechanism. A `Span` is non-escapable, so it cannot be handed
                // to a closure-taking iteration form.
                for index in span.indices {
                    storage.append(span[index])
                }
                return storage
            }
        } catch {
            throw .state
        }

        let json: JSON
        do throws(JSON.Error) {
            json = try JSON.parse(Swift.String(decoding: bytes, as: UTF8.self))
        } catch {
            throw .state
        }

        do throws(DecodingError) {
            return try json.decode(Package.Resolution.self)
        } catch {
            throw .state
        }
    }
}
