import Foundation

enum PanelStyle: String, CaseIterable {
    case notch
    case island
}

struct AppSettings {
    private static let notificationSoundKey = "notificationSound"
    private static let isMutedKey = "isMuted"
    private static let previousSoundKey = "previousNotificationSound"
    private static let isUsageEnabledKey = "isUsageEnabled"
    private static let selectedCharacterKey = "selectedCharacter"
    private static let panelStyleKey = "panelStyle"
    private static let notchScreenStyleKey = "notchScreenPanelStyle"
    private static let nonNotchScreenStyleKey = "nonNotchScreenPanelStyle"
    private static let islandOffsetXKey = "islandOffsetX"
    private static let islandOffsetYKey = "islandOffsetY"

    /// Legacy single style (kept for migration)
    static var panelStyle: PanelStyle {
        get { panelStyleFor(hasNotch: ScreenSelector.shared.selectedScreen?.hasNotch ?? false) }
        set {
            // Update both when set generically
            let screen = ScreenSelector.shared.selectedScreen
            if screen?.hasNotch == true {
                notchScreenStyle = newValue
            } else {
                nonNotchScreenStyle = newValue
            }
        }
    }

    static var notchScreenStyle: PanelStyle {
        get {
            guard let rawValue = UserDefaults.standard.string(forKey: notchScreenStyleKey),
                  let style = PanelStyle(rawValue: rawValue) else {
                return .notch
            }
            return style
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: notchScreenStyleKey)
            NotificationCenter.default.post(name: .panelStyleDidChange, object: nil)
        }
    }

    static var nonNotchScreenStyle: PanelStyle {
        get {
            guard let rawValue = UserDefaults.standard.string(forKey: nonNotchScreenStyleKey),
                  let style = PanelStyle(rawValue: rawValue) else {
                return .notch
            }
            return style
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: nonNotchScreenStyleKey)
            NotificationCenter.default.post(name: .panelStyleDidChange, object: nil)
        }
    }

    static func panelStyleFor(hasNotch: Bool) -> PanelStyle {
        hasNotch ? notchScreenStyle : nonNotchScreenStyle
    }

    static var islandOffset: CGPoint {
        get {
            let x = UserDefaults.standard.double(forKey: islandOffsetXKey)
            let y = UserDefaults.standard.double(forKey: islandOffsetYKey)
            return CGPoint(x: x, y: y)
        }
        set {
            UserDefaults.standard.set(newValue.x, forKey: islandOffsetXKey)
            UserDefaults.standard.set(newValue.y, forKey: islandOffsetYKey)
        }
    }

    static var isUsageEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: isUsageEnabledKey) }
        set { UserDefaults.standard.set(newValue, forKey: isUsageEnabledKey) }
    }

    static var anthropicApiKey: String? {
        get { KeychainManager.getAnthropicApiKey() }
        set { KeychainManager.setAnthropicApiKey(newValue) }
    }

    static var selectedCharacter: CharacterTheme {
        get {
            guard let rawValue = UserDefaults.standard.string(forKey: selectedCharacterKey),
                  let theme = CharacterTheme(rawValue: rawValue) else {
                return .notchi
            }
            return theme
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: selectedCharacterKey)
        }
    }

    static var notificationSound: NotificationSound {
        get {
            guard let rawValue = UserDefaults.standard.string(forKey: notificationSoundKey),
                  let sound = NotificationSound(rawValue: rawValue) else {
                return .purr
            }
            return sound
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: notificationSoundKey)
        }
    }

    static var isMuted: Bool {
        get { UserDefaults.standard.bool(forKey: isMutedKey) }
        set { UserDefaults.standard.set(newValue, forKey: isMutedKey) }
    }

    static func toggleMute() {
        if isMuted {
            notificationSound = previousSound ?? .purr
            isMuted = false
        } else {
            previousSound = notificationSound
            notificationSound = .none
            isMuted = true
        }
    }

    private static var previousSound: NotificationSound? {
        get {
            guard let rawValue = UserDefaults.standard.string(forKey: previousSoundKey) else {
                return nil
            }
            return NotificationSound(rawValue: rawValue)
        }
        set {
            UserDefaults.standard.set(newValue?.rawValue, forKey: previousSoundKey)
        }
    }
}
