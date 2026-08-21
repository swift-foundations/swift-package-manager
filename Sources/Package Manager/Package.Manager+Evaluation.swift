private import JSON
public import SPM_Standard

extension Package.Manager {

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
