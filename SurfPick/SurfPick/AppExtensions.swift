import SwiftUI
import SurfShared

extension Color {
    static func rating(_ r: Rating) -> Color {
        switch r {
        case .good: return Color(red: 52/255, green: 199/255, blue: 89/255)
        case .ok:   return Color(red: 255/255, green: 149/255, blue: 0/255)
        case .poor: return Color(red: 255/255, green: 59/255, blue: 48/255)
        }
    }
}

extension Bundle {
    var appVersionString: String {
        let dict = infoDictionary ?? [:]
        let version = dict["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = dict["CFBundleVersion"] as? String ?? "1"
        return "v\(version) (\(build))"
    }
}
