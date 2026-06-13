import AppIntents

/// Makes the intent discoverable in Spotlight, the Shortcuts app, and Siri.
/// At least one phrase must contain \(.applicationName) per Apple's rules.
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
