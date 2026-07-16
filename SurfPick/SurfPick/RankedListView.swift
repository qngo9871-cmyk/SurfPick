import SwiftUI
import StoreKit
import SurfShared

struct RankedListView: View {
    @StateObject private var viewModel = RankedSurfViewModel()
    @EnvironmentObject private var store: StoreKitManager
    @Environment(\.requestReview) private var requestReview
    @State private var showSettings = ProcessInfo.processInfo.arguments.contains("-previewSettings")
    @State private var showPaywall = false
    @State private var showInfo = ProcessInfo.processInfo.arguments.contains("-previewInfo")
    @State private var heroRevealDecided = false
    @State private var heroRevealed = true
    // DEBUG screenshot helper: "-previewDetail N" auto-pushes ranked break N's detail.
    @State private var screenshotDetail: RankedBreak?
    @State private var showScreenshotDetail = false

    var body: some View {
        NavigationStack {
            Group {
                switch viewModel.state {
                case .idle:
                    idleView
                case .locationExplainer:
                    locationExplainerView
                case .locating:
                    locatingView
                case .fetching:
                    fetchingView
                case .loaded:
                    loadedView
                case .errorLocation:
                    errorLocationView
                case .errorNetwork:
                    errorNetworkView
                }
            }
            .navigationTitle("Surf Pick")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if viewModel.state == .loaded {
                        Button {
                            viewModel.refresh()
                        } label: {
                            if viewModel.isRefreshing {
                                ProgressView()
                            } else {
                                Image(systemName: "arrow.clockwise")
                            }
                        }
                        .disabled(viewModel.isRefreshing)
                    }
                }
                ToolbarItem(placement: .topBarLeading) {
                    HStack(spacing: 12) {
                        Button {
                            showSettings = true
                        } label: {
                            Image(systemName: "gearshape")
                        }
                        Button {
                            showInfo = true
                        } label: {
                            Image(systemName: "info.circle")
                        }
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
                    .environmentObject(store)
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
                    .environmentObject(store)
            }
            .sheet(isPresented: $showInfo) {
                InfoView()
            }
            .navigationDestination(isPresented: $showScreenshotDetail) {
                if let b = screenshotDetail { BreakDetailView(break: b) }
            }
        }
        .task {
            if viewModel.state == .idle {
                viewModel.fetch()
            }
        }
        .onChange(of: viewModel.rankedBreaks.count) { _, count in
            let args = ProcessInfo.processInfo.arguments
            if let i = args.firstIndex(of: "-previewDetail"),
               i + 1 < args.count, let n = Int(args[i + 1]), n < count {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    screenshotDetail = viewModel.rankedBreaks[n]
                    showScreenshotDetail = true
                }
            }
        }
    }

    // MARK: - State Views

    private var idleView: some View {
        Color.clear
    }

    private var locationExplainerView: some View {
        VStack(spacing: 20) {
            Image(systemName: "location.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(.tint)
            Text("Location Needed")
                .font(.title2.bold())
            Text("Surf Pick uses your location to find the best surf spot near you right now.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 32)
            Button {
                viewModel.confirmLocationPermission()
            } label: {
                Text("Continue")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal, 40)
            .padding(.top, 8)
        }
    }

    private var locatingView: some View {
        VStack(spacing: 16) {
            ProgressView()
            Text("Finding your location…")
                .foregroundStyle(.secondary)
        }
    }

    private var fetchingView: some View {
        VStack(spacing: 16) {
            ProgressView()
            Text("Checking the breaks…")
                .foregroundStyle(.secondary)
        }
    }

    private var loadedView: some View {
        ScrollView {
            VStack(spacing: 0) {
                if let pick = viewModel.rankedBreaks.first {
                    HeroSpotCard(
                        break: pick,
                        revealed: heroRevealed,
                        priceLabel: store.displayPrice,
                        onUnlock: { showPaywall = true }
                    )
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                }

                if viewModel.rankedBreaks.count > 1 {
                    HStack {
                        Text("Other breaks nearby")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 24)
                    .padding(.bottom, 8)

                    let breaks = viewModel.rankedBreaks
                    // Paywall split (2026-07-16, matches Android): rank #2 is an individually
                    // blurred teaser, rank #3 is the one free pick, ranks #4-10 lock as a group.
                    let rank2 = breaks.count > 1 ? breaks[1] : nil
                    let rank3 = breaks.count > 2 ? breaks[2] : nil
                    let tailRows = Array(breaks.dropFirst(3))

                    LazyVStack(spacing: 8) {
                        if let rank2 {
                            if store.isPro {
                                NavigationLink {
                                    BreakDetailView(break: rank2)
                                } label: {
                                    CompactSpotRow(break: rank2)
                                }
                                .buttonStyle(.plain)
                            } else {
                                Button {
                                    showPaywall = true
                                } label: {
                                    BlurredCompactRow(break: rank2)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        if let rank3 {
                            NavigationLink {
                                BreakDetailView(break: rank3)
                            } label: {
                                CompactSpotRow(break: rank3)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 16)

                    if !tailRows.isEmpty {
                        if store.isPro {
                            LazyVStack(spacing: 8) {
                                ForEach(tailRows) { item in
                                    NavigationLink {
                                        BreakDetailView(break: item)
                                    } label: {
                                        CompactSpotRow(break: item)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.top, 8)
                        } else {
                            LockedRowsBlock(
                                rows: tailRows,
                                priceLabel: store.displayPrice,
                                onUnlock: { showPaywall = true }
                            )
                            .padding(.horizontal, 16)
                            .padding(.top, 8)
                        }
                    }
                }

                if let last = viewModel.lastUpdated {
                    Text("Updated \(last.formatted(.relative(presentation: .named)))")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .padding(.top, 24)
                        .padding(.bottom, 16)
                }
            }
        }
        .refreshable {
            viewModel.refresh()
        }
        .onAppear { decideReveal(for: viewModel.rankedBreaks.first) }
        .onChange(of: store.isPro) { _, pro in if pro { heroRevealed = true } }
    }

    /// Decides once per app session whether the #1 hero is shown or blurred.
    /// Pro always sees it; otherwise the first few opens are free, then it blurs.
    private func decideReveal(for pick: RankedBreak?) {
        guard !heroRevealDecided else { return }
        heroRevealDecided = true
        if store.isPro { heroRevealed = true; return }
        if FreeRevealStore.hasFreeRevealsLeft {
            heroRevealed = true
            FreeRevealStore.consume()
            maybeAskReview(for: pick)
        } else {
            heroRevealed = false
        }
    }

    /// Ask for a review at a delight moment — a free user who's just been shown a
    /// genuinely good pick. Once only. Targets the "many downloads, 1 review" gap.
    private func maybeAskReview(for pick: RankedBreak?) {
        guard !FreeRevealStore.reviewAsked,
              FreeRevealStore.used >= 2,
              pick?.rating == .good else { return }
        FreeRevealStore.markReviewAsked()
        requestReview()
    }

    private var errorLocationView: some View {
        VStack(spacing: 16) {
            Image(systemName: "location.slash")
                .font(.system(size: 48))
                .foregroundStyle(.red)
            Text("Location Access Denied")
                .font(.title3.bold())
            Text("Open Settings → Privacy → Location Services and enable access for Surf Pick.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 32)
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            .buttonStyle(.borderedProminent)
            Button("Retry") {
                viewModel.fetch()
            }
            .buttonStyle(.bordered)
        }
    }

    private var errorNetworkView: some View {
        VStack(spacing: 16) {
            Image(systemName: "wifi.slash")
                .font(.system(size: 48))
                .foregroundStyle(.orange)
            Text("Couldn't fetch forecast")
                .font(.title3.bold())
            Text("Check your connection and try again.")
                .foregroundStyle(.secondary)
            Button("Retry") {
                viewModel.fetch()
            }
            .buttonStyle(.borderedProminent)
        }
    }
}

// MARK: - Hero card (the #1 pick)

struct HeroSpotCard: View {
    let `break`: RankedBreak
    var revealed: Bool = true
    var priceLabel: String = "$4.99"
    var onUnlock: (() -> Void)? = nil

    var body: some View {
        Group {
            if revealed { revealedCard } else { lockedCard }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(uiColor: .secondarySystemBackground))
        )
    }

    // The full #1 pick — name, conditions, directions.
    private var revealedCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                if let rating = `break`.rating {
                    RatingDot(rating: rating, size: 36)
                } else {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 36, height: 36)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(`break`.nearby.spot.name)
                        .font(.title2.bold())
                        .lineLimit(2)
                    Text(`break`.nearby.formattedDistance)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }

            if let c = `break`.conditions {
                ConditionsRow(conditions: c, idealWindBearing: `break`.nearby.spot.idealWindBearing)
                    .padding(.top, 4)
            } else {
                Text("Conditions unavailable")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Button {
                MapsHandoff.openDirections(
                    to: `break`.nearby.spot.coordinate,
                    label: `break`.nearby.spot.name
                )
            } label: {
                HStack {
                    Image(systemName: "arrow.triangle.turn.up.right.diamond.fill")
                    Text("Get Directions")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
    }

    // The teaser — proves a better spot exists (rating + distance) but hides which
    // one it is and the conditions/directions until unlocked.
    private var lockedCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                if let rating = `break`.rating {
                    RatingDot(rating: rating, size: 36)
                } else {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 36, height: 36)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text("Your best bet right now")
                        .font(.headline)
                    Text(`break`.nearby.formattedDistance)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text(`break`.nearby.spot.name)
                        .font(.title3.bold())
                        .lineLimit(1)
                        .blur(radius: 7)
                        .accessibilityHidden(true)
                }
                Spacer()
            }

            if let c = `break`.conditions {
                ConditionsRow(conditions: c, idealWindBearing: `break`.nearby.spot.idealWindBearing)
                    .blur(radius: 6)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
            }

            Button { onUnlock?() } label: {
                VStack(spacing: 2) {
                    HStack(spacing: 8) {
                        Image(systemName: "lock.fill")
                        Text("Reveal the #1 pick")
                            .font(.headline)
                    }
                    Text("See which break + get directions · one-time \(priceLabel)")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.85))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
    }
}

// MARK: - Compact list row (positions 2–10)

struct CompactSpotRow: View {
    let `break`: RankedBreak

    var body: some View {
        HStack(spacing: 12) {
            if let rating = `break`.rating {
                RatingDot(rating: rating, size: 18)
            } else {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 18, height: 18)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(`break`.nearby.spot.name)
                    .font(.body.weight(.medium))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                if let c = `break`.conditions {
                    Text("\(String(format: "%.1f", c.waveHeight))m · \(c.wavePeriod)s · \(c.windSpeed)k \(compassDirection(from: c.windDirection))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                } else {
                    Text("Conditions unavailable")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }

            Spacer()

            Text(`break`.nearby.formattedDistance)
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(uiColor: .secondarySystemBackground))
        )
    }
}

// MARK: - Rank #2's individually blurred teaser row

/// Rating + distance visible, name/conditions blurred, taps through to the paywall.
struct BlurredCompactRow: View {
    let `break`: RankedBreak

    var body: some View {
        HStack(spacing: 12) {
            if let rating = `break`.rating {
                RatingDot(rating: rating, size: 18)
            } else {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 18, height: 18)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(`break`.nearby.spot.name)
                    .font(.body.weight(.medium))
                    .lineLimit(1)
                    .blur(radius: 5)
                    .accessibilityHidden(true)
                if let c = `break`.conditions {
                    Text("\(String(format: "%.1f", c.waveHeight))m · \(c.wavePeriod)s · \(c.windSpeed)k \(compassDirection(from: c.windDirection))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .blur(radius: 5)
                        .accessibilityHidden(true)
                }
            }

            Spacer()

            Text(`break`.nearby.formattedDistance)
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
            Image(systemName: "lock.fill")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(uiColor: .secondarySystemBackground))
        )
    }
}

// MARK: - Locked rows (free tier paywall)

struct LockedRowsBlock: View {
    let rows: [RankedBreak]
    let priceLabel: String
    let onUnlock: () -> Void

    var body: some View {
        ZStack {
            VStack(spacing: 8) {
                ForEach(rows) { item in
                    CompactSpotRow(break: item)
                }
            }
            .blur(radius: 6)
            .allowsHitTesting(false)
            .accessibilityHidden(true)

            Button(action: onUnlock) {
                VStack(spacing: 6) {
                    HStack(spacing: 8) {
                        Image(systemName: "lock.fill")
                        Text("Unlock \(rows.count) more spots")
                            .font(.headline)
                    }
                    Text("One-time \(priceLabel)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.accentColor.opacity(0.4), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            .foregroundStyle(.primary)
        }
    }
}

// MARK: - Reusable bits

struct RatingDot: View {
    let rating: Rating
    let size: CGFloat

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: size, height: size)
    }

    private var color: Color { .rating(rating) }
}

struct ConditionsRow: View {
    let conditions: SurfConditions
    let idealWindBearing: Int

    var body: some View {
        HStack(spacing: 16) {
            ConditionItem(
                icon: "water.waves",
                value: "\(String(format: "%.1f", conditions.waveHeight))m",
                label: "\(conditions.wavePeriod)s"
            )
            Divider().frame(height: 32)
            ConditionItem(
                icon: "wind",
                value: "\(conditions.windSpeed)k",
                label: "\(compassDirection(from: conditions.windDirection)) · \(windTypeLabel)"
            )
            Spacer()
        }
    }

    private var windTypeLabel: String {
        let type = ConditionsCalculator.windType(
            windDirection: conditions.windDirection,
            idealWindBearing: idealWindBearing
        )
        return ConditionsCalculator.windTypeLabel(type)
    }
}

struct ConditionItem: View {
    let icon: String
    let value: String
    let label: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(.secondary)
            VStack(alignment: .leading, spacing: 0) {
                Text(value)
                    .font(.headline)
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    RankedListView()
}
