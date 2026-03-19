import AppKit

extension NSScreen {
    /// Returns the built-in MacBook display, falling back to the main screen
    static var builtInOrMain: NSScreen {
        screens.first { $0.isBuiltIn } ?? main!
    }

    /// Whether this screen is the built-in display (MacBook's internal screen)
    var isBuiltIn: Bool {
        guard let screenNumber = deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID else {
            return false
        }
        return CGDisplayIsBuiltin(screenNumber) != 0
    }

    /// Whether this screen has a notch (safeAreaInsets.top > 0)
    var hasNotch: Bool {
        safeAreaInsets.top > 0
    }

    /// The height of the menu bar area on this display.
    var menuBarHeight: CGFloat {
        let topInset = max(0, frame.maxY - visibleFrame.maxY)
        let fallback = NSStatusBar.system.thickness
        return max(topInset, fallback)
    }

    /// Calculates the notch dimensions for this screen
    var notchSize: CGSize {
        guard hasNotch else {
            return CGSize(width: 224, height: menuBarHeight)
        }

        let fullWidth = frame.width
        let leftPadding = auxiliaryTopLeftArea?.width ?? 0
        let rightPadding = auxiliaryTopRightArea?.width ?? 0
        let notchWidth = fullWidth - leftPadding - rightPadding + 4
        let notchHeight = safeAreaInsets.top + 2

        return CGSize(width: notchWidth, height: notchHeight)
    }

    /// Calculates the window frame centered at the notch position
    var notchWindowFrame: CGRect {
        let size = notchSize
        let originX = frame.origin.x + (frame.width - size.width) / 2
        let originY = frame.maxY - size.height
        return CGRect(x: originX, y: originY, width: size.width, height: size.height)
    }
}
