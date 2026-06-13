# Surf Pick — App Intents / Siri AI Adoption Handover

**Target:** Add App Intents support so Surf Pick is reachable from Siri AI (iOS 27) and Spotlight.
**Pilot scope:** One intent — "best/nearest surf break right now" — done properly. No feature creep.
**Bundle:** com.quyenngo.surfpick
**Shared logic:** SurfShared Swift Package (Open-Meteo Marine API, break ranking)
**Status:** API signatures reconciled against actual SurfShared source (13 Jun 2026) and WWDC 2026 confirmed details. Ready for CLC build. Remaining ⚠️ items are minor and noted inline.

---

## 0. What changed from the original scaffold (read first)

The original draft (8–9 Jun) guessed some signatures. Corrected against real source:

- **There is no single "ranking function."** The app fetches conditions per spot then rates each. The intent must do the same:
  1. `SurfSpotFinder().findNearest(to:count:)` → `[NearbySpot]`
  2. For each, `ForecastService().fetchConditions(latitude:longitude:)` (async throws) → `SurfConditions`
  3. `ConditionsCalculator.overallRating(conditions:idealWindBearing:)` → `Rating`
  4. Pick the best `Rating` (lowest rawValue; `.good = 0`).
- **`Rating` is a 3-level enum** (`good`/`ok`/`poor`), NOT a 0–10 score. The old snippet showing `"\(rating)/10"` was wrong and would not compile. Snippet now shows a word/colour.
- **Dataset is fine.** The Ballina-area spots are hand-curated against Google Maps (commit `cf0817e`). No coordinate fix needed before building.

---

## 1. Why three pieces

iOS 27 guidance: adopt **entity schemas**, **intent schemas**, and **View Annotations** so Siri AI discovers and acts on in-app features via natural language. Mapped to Surf Pick:

- **Entity** → a surf break (`SurfBreakEntity`). The noun Siri reasons about.
- **Intent** → rank nearest breaks by current conditions (`FindBestBreakIntent`). The verb.
- **View Annotation** → mark the result view so Siri surfaces it inline (the on-screen-awareness API confirmed at WWDC 2026).

---

## 2. WWDC 2026 confirmations (resolved VERIFY markers)

- **App Intents is now the mandatory Siri path.** SiriKit is formally deprecated (~2–3 yr window, ≈ iOS 29 / fall 2028). Do NOT use SiriKit anywhere here.
- **View Annotations API** is the real name for mapping views to entities for on-screen reference. Use it for the result view (see §5).
- **App Intents Testing framework** (new): validates the integration through real system pathways without UI automation. Use it for §7 tests instead of simulator UI driving.
- **Per-intent privacy manifest**: you can declare whether an intent's Siri interaction may go to cloud or must stay on-device. Surf data is non-sensitive → cloud is fine; set the permissive value, no special handling.
- ⚠️ The exact spelling of the View Annotation modifier is still worth a 2-min confirm against the "Bring your app to Siri" session video before relying on it. Everything else below uses stable iOS 16–18 App Intents API that is unchanged.

---

## 3. File layout (add to existing target via XcodeGen)

```
SurfPick/
  Intents/
    SurfBreakEntity.swift        // AppEntity + query
    FindBestBreakIntent.swift    // AppIntent (fetch + rank loop)
    SurfPickShortcuts.swift      // AppShortcutsProvider
  Views/
    BreakRankingSnippet.swift    // snippet view for Siri result
```

Intents layer is a thin adapter over SurfShared. Do NOT duplicate ranking or fetch logic.

---

## 4. SurfBreakEntity

```swift
import AppIntents
import SurfShared

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
        // Map identifiers back to SurfBreakEntity. For the pilot, the intent
        // produces entities directly, so this can return [] or look up by name.
        []
    }
    // suggestedEntities() optional; the dataset's local hand-curated spots are
    // the only ones safe to suggest. Keep empty for pilot to avoid surfacing
    // unverified non-Ballina coordinates.
}
```

---

## 5. FindBestBreakIntent (the core — fetch + rank loop)

```swift
import AppIntents
import CoreLocation
import SurfShared

struct FindBestBreakIntent: AppIntent {
    static var title: LocalizedStringResource = "Find Best Surf Break"
    static var description = IntentDescription("Tells you the best nearby surf break right now.")

    // Hands-free spoken answer; do not bounce into the app.
    static var openAppWhenRun = false

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog & ShowsSnippetView {
        // 1. Location (App Intents grants a one-shot location request)
        let loc = try await currentLocation()

        // 2. Nearest spots
        let nearby = SurfSpotFinder().findNearest(to: loc, count: 5)
        guard !nearby.isEmpty else {
            return .result(dialog: "I couldn't find any surf breaks near you.")
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
            return .result(dialog: "I found breaks nearby but couldn't load conditions right now.")
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
        switch r { case .good: return "good"; case .ok: return "ok"; case .poor: return "poor" }
    }

    // ⚠️ VERIFY: confirm the App Intents one-shot location helper name in the
    // session video. Pattern below is the standard CLLocationManager async wrap;
    // if Apple's IntentLocation API is cleaner, prefer it.
    private func currentLocation() async throws -> CLLocation {
        // CLC: reuse SurfShared.LocationManager if it already exposes an async
        // one-shot; otherwise wrap CLLocationManager.requestLocation() in a
        // continuation here. Do NOT add background location.
        fatalError("CLC: wire to SurfShared.LocationManager one-shot")
    }
}
```

---

## 6. BreakRankingSnippet (Siri inline result)

```swift
import SwiftUI
import SurfShared

struct BreakRankingSnippet: View {
    let breaks: [SurfBreakEntity]
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(breaks, id: \.id) { b in
                HStack {
                    Text(b.name)
                    Spacer()
                    Text(b.ratingLabel.capitalized)
                        .foregroundStyle(color(for: b.ratingLabel))
                }
            }
        }
        .padding()
        // ⚠️ VERIFY View Annotation modifier spelling against session video.
    }
    private func color(for label: String) -> Color {
        switch label.lowercased() {
        case "good": return .green
        case "ok":   return .orange
        default:     return .red
        }
    }
}
```

---

## 7. SurfPickShortcuts (discoverability)

```swift
import AppIntents

struct SurfPickShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: FindBestBreakIntent(),
            phrases: [
                "Best surf break in \(.applicationName)",
                "Where should I surf with \(.applicationName)",
                "\(.applicationName) surf check"
            ],
            shortTitle: "Best Break",
            systemImageName: "water.waves"
        )
    }
}
```

`\(.applicationName)` required in at least one phrase per Apple's rules.

---

## 8. Build & verify (CLC, no Xcode GUI)

1. Add Intents files + snippet to the target via the XcodeGen project spec (regenerate; don't hand-edit pbxproj).
2. `xcodebuild` for a simulator destination to confirm compile.
3. Write intent tests using the new **App Intents Testing framework** (no UI automation).
4. Device test: trigger via Siri ("Surf Pick surf check") and Spotlight; confirm spoken dialog + snippet render.
5. Confirm location wiring uses SurfShared.LocationManager one-shot, no background location added.

---

## 9. Out of scope for pilot

- No second intent ("add to favourites", "high-tide reminder"). One intent, done well.
- No widget/Live Activity changes.
- No change to the $4.99 Pro unlock. Intent is free-tier.
- Do not touch SurfShared ranking/fetch logic. Adapter only.

---

## 10. Transfer value

Once working, the entity → intent → annotated-view pattern ports to:
- **Big Things AU** — `BigThingEntity` + `FindNearestBigThingIntent`
- **Qi** — deliberately last; needs reconciliation with its own assistant pipeline
- **NightEase** — event-driven, no natural voice surface; skip

Surf Pick is the reference implementation.
