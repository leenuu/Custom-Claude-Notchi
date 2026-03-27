import AppKit
import os.log
import Sparkle
import SwiftUI

private let logger = Logger(subsystem: "com.ruban.notchi", category: "AppDelegate")

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var notchPanel: NotchPanel?
    private let windowHeight: CGFloat = 500

    private let updater: SPUUpdater
    private let userDriver: NotchUserDriver
    private var updaterStarted = false

    override init() {
        userDriver = NotchUserDriver()
        updater = SPUUpdater(
            hostBundle: Bundle.main,
            applicationBundle: Bundle.main,
            userDriver: userDriver,
            delegate: nil
        )
        super.init()

        UpdateManager.shared.setUpdater(updater)

        do {
            try updater.start()
            updaterStarted = true
            logger.info("Sparkle updater started successfully")
            logger.info("Feed URL: \(self.updater.feedURL?.absoluteString ?? "nil")")
            logger.info("canCheckForUpdates: \(self.updater.canCheckForUpdates)")
        } catch {
            logger.error("Failed to start Sparkle updater: \(error.localizedDescription)")
        }
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApplication.shared.setActivationPolicy(.accessory)
        setupNotchWindow()
        observeScreenChanges()
        observeWakeNotifications()
        startHookServices()
        startUsageService()
        if updaterStarted {
            logger.info("Triggering update check on launch")
            updater.checkForUpdates()
        } else {
            logger.warning("Updater not started, skipping update check")
        }
    }

    private func startHookServices() {
        HookInstaller.installIfNeeded()
        SocketServer.shared.start { event in
            Task { @MainActor in
                NotchiStateMachine.shared.handleEvent(event)
            }
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    @MainActor private func setupNotchWindow() {
        ScreenSelector.shared.refreshScreens()
        guard let screen = ScreenSelector.shared.selectedScreen else { return }
        NotchPanelManager.shared.updateGeometry(for: screen)

        let panel = NotchPanel(frame: windowFrame(for: screen), hasNotch: screen.hasNotch)

        let contentView = NotchContentView()
        let hostingView = NSHostingView(rootView: contentView)

        let hitTestView = NotchHitTestView()
        hitTestView.panelManager = NotchPanelManager.shared
        hitTestView.addSubview(hostingView)
        hostingView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hostingView.topAnchor.constraint(equalTo: hitTestView.topAnchor),
            hostingView.bottomAnchor.constraint(equalTo: hitTestView.bottomAnchor),
            hostingView.leadingAnchor.constraint(equalTo: hitTestView.leadingAnchor),
            hostingView.trailingAnchor.constraint(equalTo: hitTestView.trailingAnchor),
        ])

        panel.contentView = hitTestView
        panel.orderFrontRegardless()

        self.notchPanel = panel
    }

    private func observeScreenChanges() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(repositionWindow),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
    }

    private func observeWakeNotifications() {
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(handleSystemWake),
            name: NSWorkspace.didWakeNotification,
            object: nil
        )
    }

    @objc private func handleSystemWake() {
        MainActor.assumeIsolated {
            logger.info("System woke, restarting Claude usage polling")
            ClaudeUsageService.shared.startPolling()
        }
    }

    @objc private func repositionWindow() {
        MainActor.assumeIsolated {
            guard let panel = notchPanel else { return }
            ScreenSelector.shared.refreshScreens()
            guard let screen = ScreenSelector.shared.selectedScreen else { return }

            NotchPanelManager.shared.updateGeometry(for: screen)
            panel.setFrame(windowFrame(for: screen), display: true)
        }
    }

    private func windowFrame(for screen: NSScreen) -> NSRect {
        let screenFrame = screen.frame
        let height = AppSettings.panelStyle == .island ? screenFrame.height : windowHeight
        return NSRect(
            x: screenFrame.origin.x,
            y: screenFrame.maxY - height,
            width: screenFrame.width,
            height: height
        )
    }

    @MainActor private func startUsageService() {
        ClaudeUsageService.shared.startPolling()
    }

}
