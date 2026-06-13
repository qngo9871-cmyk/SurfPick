import AppIntents
import CoreLocation
import SwiftUI      // brings in the _AppIntents_SwiftUI overlay so `.result(dialog:view:)` resolves
import SurfShared

/// The verb: fetch conditions for the nearest breaks and tell the user the best
/// one right now. Thin adapter — fetch + rank loop reuses SurfShared exactly as
/// the app does (SurfSpotFinder → ForecastService → ConditionsCalculator).
struct FindBestBreakIntent: AppIntent {
    static var title: LocalizedStringResource = "Find Best Surf Break"
    static var description = IntentDescription("Tells you the best nearby surf break right now.")

    // Hands-free spoken answer; do not bounce into the app.
    static var openAppWhenRun = false

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog & ShowsSnippetView {
        // 1. Location — App Intents grants a one-shot request. Reuse SurfShared's
        //    LocationManager async one-shot (same call the app's view model makes).
        let loc = try await currentLocation()

        // 2. Nearest spots
        let nearby = SurfSpotFinder().findNearest(to: loc, count: 5)
        guard !nearby.isEmpty else {
            throw SurfIntentError.noNearbyBreaks
        }

        // 3. Fetch + rate each
        let service = ForecastService()
        var ranked: [(NearbySpot, Rating)] = []
        for ns in nearby {
            if let cond = try? await service.fetchConditions(
                latitude: ns.spot.latitude, longitude: ns.spot.longitude) {
                let r = ConditionsCalculator.overallRating(
                    conditions: cond, idealWindBearing: ns.spot.idealWindBearing)
                ranked.append((ns, r))
            }
        }
        guard !ranked.isEmpty else {
            throw SurfIntentError.noConditions
        }

        // 4. Best = lowest Rating rawValue (.good = 0)
        ranked.sort { $0.1 < $1.1 }
        let best = ranked[0]
        let label = ratingWord(best.1)

        let entities = ranked.map { (ns, r) in
            SurfBreakEntity(id: ns.spot.id, name: ns.spot.name, ratingLabel: ratingWord(r))
        }

        let spoken = "\(best.0.spot.name) is your best bet right now — conditions are \(label), \(best.0.formattedDistance)."

        return .result(
            dialog: IntentDialog(stringLiteral: spoken),
            view: BreakRankingSnippet(breaks: entities)
        )
    }

    private func ratingWord(_ r: Rating) -> String {
        switch r {
        case .good: return "good"
        case .ok:   return "ok"
        case .poor: return "poor"
        }
    }

    // VERIFY (resolved): SurfShared.LocationManager already exposes an async
    // one-shot — `requestLocation(forceFresh:) async throws -> CLLocation` — which
    // wraps CLLocationManager.requestLocation() in a continuation with an 8s
    // timeout. No need to hand-roll a continuation or Apple's IntentLocation API,
    // and no background location is added. This is the exact call the app's view
    // model makes (RankedSurfViewModel).
    private func currentLocation() async throws -> CLLocation {
        try await LocationManager().requestLocation()
    }
}

/// Spoken failure messages. Returned as thrown errors (not dialog-only results)
/// so the intent's success return type stays `…& ShowsSnippetView`; Siri speaks
/// the localizedStringResource.
enum SurfIntentError: Error, CustomLocalizedStringResourceConvertible {
    case noNearbyBreaks
    case noConditions

    var localizedStringResource: LocalizedStringResource {
        switch self {
        case .noNearbyBreaks:
            return "I couldn't find any surf breaks near you."
        case .noConditions:
            return "I found breaks nearby but couldn't load conditions right now."
        }
    }
}
