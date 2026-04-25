import Foundation
import UIKit
import CoreLocation

/// Opens turn-by-turn directions to a surf break.
///
/// Default behaviour: try Google Maps first; if Google Maps isn't installed, fall back to Apple Maps.
/// Q's preference (most surfers use Google Maps), with Apple Maps as the always-available fallback.
///
/// The user can change the default via UserDefaults key "preferredMapsApp" — values: "google" or "apple".
enum MapsHandoff {

    enum Provider: String {
        case google
        case apple

        var displayName: String {
            switch self {
            case .google: return "Google Maps"
            case .apple:  return "Apple Maps"
            }
        }
    }

    /// User's preferred maps app. Defaults to Google Maps.
    static var preferredProvider: Provider {
        get {
            let raw = UserDefaults.standard.string(forKey: "preferredMapsApp") ?? Provider.google.rawValue
            return Provider(rawValue: raw) ?? .google
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: "preferredMapsApp")
        }
    }

    /// Returns true if Google Maps is installed on this device.
    /// Requires LSApplicationQueriesSchemes to include "comgooglemaps" in Info.plist.
    static var isGoogleMapsInstalled: Bool {
        guard let url = URL(string: "comgooglemaps://") else { return false }
        return UIApplication.shared.canOpenURL(url)
    }

    /// Open directions to a coordinate using the user's preferred maps app,
    /// falling back to Apple Maps if Google Maps isn't installed.
    static func openDirections(to coordinate: CLLocationCoordinate2D, label: String) {
        switch preferredProvider {
        case .google:
            if isGoogleMapsInstalled {
                openGoogleMaps(to: coordinate, label: label)
            } else {
                openAppleMaps(to: coordinate, label: label)
            }
        case .apple:
            openAppleMaps(to: coordinate, label: label)
        }
    }

    /// Force a specific provider, useful for the "Open in..." sheet.
    static func openDirections(to coordinate: CLLocationCoordinate2D, label: String, using provider: Provider) {
        switch provider {
        case .google:
            if isGoogleMapsInstalled {
                openGoogleMaps(to: coordinate, label: label)
            } else {
                // Google requested but not installed — fall back to Apple Maps to avoid silent failure
                openAppleMaps(to: coordinate, label: label)
            }
        case .apple:
            openAppleMaps(to: coordinate, label: label)
        }
    }

    // MARK: - Private

    private static func openGoogleMaps(to coordinate: CLLocationCoordinate2D, label: String) {
        // comgooglemaps://?daddr=lat,lon&directionsmode=driving
        var components = URLComponents()
        components.scheme = "comgooglemaps"
        components.host = ""
        components.queryItems = [
            URLQueryItem(name: "daddr", value: "\(coordinate.latitude),\(coordinate.longitude)"),
            URLQueryItem(name: "directionsmode", value: "driving"),
            URLQueryItem(name: "q", value: label)
        ]

        if let url = components.url {
            UIApplication.shared.open(url)
        }
    }

    private static func openAppleMaps(to coordinate: CLLocationCoordinate2D, label: String) {
        // http://maps.apple.com/?daddr=lat,lon&dirflg=d
        // Using maps.apple.com URL form (auto-opens in Apple Maps app on iOS).
        var components = URLComponents(string: "http://maps.apple.com/")
        let encodedLabel = label.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? label
        components?.queryItems = [
            URLQueryItem(name: "daddr", value: "\(coordinate.latitude),\(coordinate.longitude)"),
            URLQueryItem(name: "dirflg", value: "d"),
            URLQueryItem(name: "q", value: encodedLabel)
        ]

        if let url = components?.url {
            UIApplication.shared.open(url)
        }
    }
}
