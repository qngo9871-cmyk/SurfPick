import SwiftUI
import SurfShared

/// Inline result Siri shows alongside the spoken dialog. Surfaced via the
/// intent's `ShowsSnippetView` conformance — the documented, stable mechanism
/// for an App Intent to return a view (iOS 16+).
///
/// VERIFY (resolved): the handover flagged a possible WWDC 2026 "View Annotation"
/// modifier for on-screen-awareness. It is net-new and unconfirmed, and applying
/// an unverified modifier name would break compilation — defeating the build
/// gate. `ShowsSnippetView` already surfaces this view inline in the Siri result,
/// so no speculative annotation is added. If/when the modifier name is confirmed
/// against the "Bring your app to Siri" session, add it here as a 2-line change.
struct BreakRankingSnippet: View {
    let breaks: [SurfBreakEntity]
    /// When false (free tier), break names are blurred so the spoken/visual
    /// answer matches the on-screen paywall — Pro is required to reveal them.
    var revealed: Bool = true
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(breaks, id: \.id) { b in
                HStack {
                    Text(b.name)
                        .blur(radius: revealed ? 0 : 6)
                    Spacer()
                    Text(b.ratingLabel.capitalized)
                        .foregroundStyle(color(for: b.ratingLabel))
                }
            }
            if !revealed {
                Text("Open Surf Pick to reveal the breaks")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
    }

    private func color(for label: String) -> Color {
        switch label.lowercased() {
        case "good": return .green
        case "ok":   return .orange
        default:     return .red
        }
    }
}
