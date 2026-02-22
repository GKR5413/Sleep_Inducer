import Foundation

enum StrictnessMode: String, Codable, CaseIterable, Identifiable {
    case strict
    case flexible

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .strict: return "Strict"
        case .flexible: return "Flexible"
        }
    }

    var description: String {
        switch self {
        case .strict: return "Cannot cancel until time is up"
        case .flexible: return "Cancel with a 30-second delay"
        }
    }
}
