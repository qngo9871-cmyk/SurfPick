import AppIntents
import SurfShared

/// The noun Siri reasons about: a single surf break with its current rating.
/// Thin adapter over SurfShared's `SurfSpot` / `Rating` — no logic of its own.
struct SurfBreakEntity: AppEntity {
    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Surf Break")
    static var defaultQuery = SurfBreakQuery()

    let id: String          // SurfSpot.id == name
    let name: String
    var ratingLabel: String // "Good" / "OK" / "Poor" — from Rating, set when ranked

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)", subtitle: "\(ratingLabel) right now")
    }
}

struct SurfBreakQuery: EntityQuery {
    func entities(for identifiers: [String]) async throws -> [SurfBreakEntity] {
        // The intent produces ranked entities directly, so there is nothing to
        // resolve back here for the pilot. Returning [] is correct: we do not
        // surface unverified non-Ballina coordinates as standalone suggestions.
        []
    }
}
