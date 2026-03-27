import AppKit

@MainActor
@Observable
final class NotchPanelManager {
    static let shared = NotchPanelManager()

    private(set) var isExpanded = false
    private(set) var isPinned = false
    private(set) var notchSize: CGSize = .zero
    private(set) var notchRect: CGRect = .zero
    private(set) var panelRect: CGRect = .zero
    private(set) var hasNotch: Bool = false
    private(set) var isIslandMode: Bool = false
    private var screenHeight: CGFloat = 0

    private var mouseDownMonitor: EventMonitor?
    private var mouseUpMonitor: EventMonitor?
    private var mouseDownLocation: NSPoint?

    private init() {
        setupEventMonitors()
    }

    func updateGeometry(for screen: NSScreen) {
        let newNotchSize = screen.notchSize
        let screenFrame = screen.frame

        notchSize = newNotchSize
        hasNotch = screen.hasNotch
        isIslandMode = AppSettings.panelStyleFor(hasNotch: screen.hasNotch) == .island

        let notchCenterX = screenFrame.origin.x + screenFrame.width / 2
        let sideWidth = max(0, newNotchSize.height - 12) + 24
        let notchTotalWidth = newNotchSize.width + sideWidth

        notchRect = CGRect(
            x: notchCenterX - notchTotalWidth / 2,
            y: screenFrame.maxY - newNotchSize.height,
            width: notchTotalWidth,
            height: newNotchSize.height
        )

        let panelSize = NotchConstants.expandedPanelSize
        let panelWidth = panelSize.width + NotchConstants.expandedPanelHorizontalPadding
        panelRect = CGRect(
            x: notchCenterX - panelWidth / 2,
            y: screenFrame.maxY - panelSize.height,
            width: panelWidth,
            height: panelSize.height
        )

        if isIslandMode {
            let islandWidth: CGFloat = 300
            let islandHeight: CGFloat = 44
            let menuBarHeight = screen.menuBarHeight
            let gapBelowMenuBar: CGFloat = 6

            // Override notchSize for island so the header uses island dimensions
            notchSize = CGSize(width: islandWidth, height: islandHeight)

            let userOffset = AppSettings.islandOffset
            let islandX = notchCenterX - islandWidth / 2 + userOffset.x
            let islandY = screenFrame.maxY - menuBarHeight - gapBelowMenuBar - islandHeight + userOffset.y

            notchRect = CGRect(
                x: islandX,
                y: islandY,
                width: islandWidth,
                height: islandHeight
            )

            let panelSize = NotchConstants.expandedPanelSize
            let panelWidth = panelSize.width + NotchConstants.expandedPanelHorizontalPadding
            let panelHeight = panelSize.height
            panelRect = CGRect(
                x: islandX + (islandWidth - panelWidth) / 2,
                y: islandY + islandHeight - panelHeight,
                width: panelWidth,
                height: panelHeight
            )
        }

        screenHeight = screenFrame.height
    }

    private func setupEventMonitors() {
        mouseDownMonitor = EventMonitor(mask: .leftMouseDown) { [weak self] _ in
            Task { @MainActor in
                self?.handleMouseDown()
            }
        }
        mouseDownMonitor?.start()

        mouseUpMonitor = EventMonitor(mask: .leftMouseUp) { [weak self] _ in
            Task { @MainActor in
                self?.handleMouseUp()
            }
        }
        mouseUpMonitor?.start()
    }

    private func handleMouseDown() {
        let location = NSEvent.mouseLocation
        mouseDownLocation = location

        if isExpanded {
            if !isPinned && !panelRect.contains(location) {
                collapse()
            }
        } else if !isIslandMode {
            // Notch mode: expand immediately on click
            if notchRect.contains(location) {
                expand()
            }
        }
        // Island mode: wait for mouseUp to distinguish tap vs drag
    }

    private func handleMouseUp() {
        guard isIslandMode, !isExpanded else {
            mouseDownLocation = nil
            return
        }

        let upLocation = NSEvent.mouseLocation
        guard let downLocation = mouseDownLocation else { return }
        mouseDownLocation = nil

        // Only expand if mouse didn't move much (tap, not drag)
        let dx = abs(upLocation.x - downLocation.x)
        let dy = abs(upLocation.y - downLocation.y)
        if dx < 5 && dy < 5 && notchRect.contains(upLocation) {
            expand()
        }
    }

    func expand() {
        guard !isExpanded else { return }
        isExpanded = true
    }

    func collapse() {
        guard isExpanded else { return }
        isExpanded = false
        isPinned = false
    }

    func toggle() {
        if isExpanded {
            collapse()
        } else {
            expand()
        }
    }

    func togglePin() {
        isPinned.toggle()
    }
}
