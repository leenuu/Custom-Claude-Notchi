import Foundation

enum CharacterTheme: String, CaseIterable, Identifiable {
    case notchi
    case bocchi

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .notchi: return "Notchi"
        case .bocchi: return "Bocchi"
        }
    }

    var spritePrefix: String {
        switch self {
        case .notchi: return "notchi"
        case .bocchi: return "bocchi"
        }
    }

    /// Idle neutral sprite name, used for settings preview thumbnail
    var previewSprite: String {
        "\(spritePrefix)_idle_neutral"
    }
}
