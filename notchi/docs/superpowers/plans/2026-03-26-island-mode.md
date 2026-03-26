# Dynamic Island Mode Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a "Dynamic Island" panel style option that shows notchi as a floating rounded capsule below the menu bar, selectable via settings.

**Architecture:** Add `PanelStyle` enum to `AppSettings`, then branch on it in `NotchContentView` (clip shape, padding, shadow/border), `NotchPanelManager` (geometry), and `NotchPanel` (window level). Existing notch code is untouched — island mode adds parallel branches.

**Tech Stack:** SwiftUI, AppKit (NSPanel), UserDefaults

---

### Task 1: Add PanelStyle enum and setting

**Files:**
- Modify: `notchi/Core/AppSettings.swift`

- [ ] **Step 1: Add PanelStyle enum and panelStyle property**

```swift
// Add above struct AppSettings
enum PanelStyle: String, CaseIterable {
    case notch
    case island
}
```

```swift
// Add inside struct AppSettings, after selectedCharacterKey
private static let panelStyleKey = "panelStyle"

static var panelStyle: PanelStyle {
    get {
        guard let rawValue = UserDefaults.standard.string(forKey: panelStyleKey),
              let style = PanelStyle(rawValue: rawValue) else {
            return .notch
        }
        return style
    }
    set {
        UserDefaults.standard.set(newValue.rawValue, forKey: panelStyleKey)
        NotificationCenter.default.post(name: .panelStyleDidChange, object: nil)
    }
}
```

- [ ] **Step 2: Add notification name**

Add to `NotchContentView.swift` in the `Notification.Name` extension:

```swift
static let panelStyleDidChange = Notification.Name("panelStyleDidChange")
```

- [ ] **Step 3: Build and verify**

Run: `xcodebuild -project notchi.xcodeproj -scheme notchi -configuration Debug build`
Expected: BUILD SUCCEEDED

- [ ] **Step 4: Commit**

```bash
git add notchi/Core/AppSettings.swift notchi/NotchContentView.swift
git commit -m "feat: add PanelStyle enum (notch/island) with UserDefaults persistence"
```

---

### Task 2: Add panel style picker to settings UI

**Files:**
- Modify: `notchi/Views/PanelSettingsView.swift`

- [ ] **Step 1: Add state and picker to displaySection**

Add a `@State` property at the top of `PanelSettingsView`:

```swift
@State private var panelStyle = AppSettings.panelStyle
```

Add the style picker as the first item in `displaySection`:

```swift
private var displaySection: some View {
    VStack(alignment: .leading, spacing: 12) {
        SettingsRowView(icon: "rectangle.topthird.inset.filled", title: "Panel Style") {
            Picker("", selection: $panelStyle) {
                Text("노치").tag(PanelStyle.notch)
                Text("아일랜드").tag(PanelStyle.island)
            }
            .pickerStyle(.segmented)
            .frame(width: 140)
            .onChange(of: panelStyle) { _, newValue in
                AppSettings.panelStyle = newValue
            }
        }

        CharacterPickerView()

        ScreenPickerRow(screenSelector: ScreenSelector.shared)

        SoundPickerView()
    }
}
```

- [ ] **Step 2: Build and verify**

Run: `xcodebuild -project notchi.xcodeproj -scheme notchi -configuration Debug build`
Expected: BUILD SUCCEEDED

- [ ] **Step 3: Commit**

```bash
git add notchi/Views/PanelSettingsView.swift
git commit -m "feat: add panel style segmented picker to settings (노치/아일랜드)"
```

---

### Task 3: Add isIslandMode to NotchPanelManager and adjust geometry

**Files:**
- Modify: `notchi/Services/NotchPanelManager.swift`

- [ ] **Step 1: Add isIslandMode property and adjust geometry**

Add property after `hasNotch`:

```swift
private(set) var isIslandMode: Bool = false
```

Update `updateGeometry(for:)` to account for island mode. Add at the start of the method:

```swift
isIslandMode = AppSettings.panelStyle == .island
```

After the existing `notchRect` calculation, add island mode override:

```swift
if isIslandMode {
    let islandWidth: CGFloat = 200
    let islandHeight: CGFloat = 36
    let menuBarHeight = screen.menuBarHeight
    let gapBelowMenuBar: CGFloat = 5

    notchRect = CGRect(
        x: notchCenterX - islandWidth / 2,
        y: screenFrame.maxY - menuBarHeight - gapBelowMenuBar - islandHeight,
        width: islandWidth,
        height: islandHeight
    )

    let panelSize = NotchConstants.expandedPanelSize
    let panelWidth = panelSize.width + NotchConstants.expandedPanelHorizontalPadding
    panelRect = CGRect(
        x: notchCenterX - panelWidth / 2,
        y: screenFrame.maxY - menuBarHeight - gapBelowMenuBar - panelSize.height,
        width: panelWidth,
        height: panelSize.height
    )
}
```

- [ ] **Step 2: Build and verify**

Run: `xcodebuild -project notchi.xcodeproj -scheme notchi -configuration Debug build`
Expected: BUILD SUCCEEDED

- [ ] **Step 3: Commit**

```bash
git add notchi/Services/NotchPanelManager.swift
git commit -m "feat: adjust NotchPanelManager geometry for island mode"
```

---

### Task 4: Update NotchPanel window level for island mode

**Files:**
- Modify: `notchi/NotchPanel.swift`

- [ ] **Step 1: Add panelStyle parameter and branch**

Change `init(frame:hasNotch:)` to also consider island mode. Replace the current init:

```swift
init(frame: CGRect, hasNotch: Bool = true) {
    super.init(
        contentRect: frame,
        styleMask: [.borderless, .nonactivatingPanel],
        backing: .buffered,
        defer: false
    )

    isFloatingPanel = true
    becomesKeyOnlyIfNeeded = true

    let isIsland = AppSettings.panelStyle == .island

    if isIsland {
        level = .statusBar
        collectionBehavior = [
            .fullScreenAuxiliary,
            .canJoinAllSpaces,
            .ignoresCycle
        ]
    } else if hasNotch {
        level = .mainMenu + 3
        collectionBehavior = [
            .fullScreenAuxiliary,
            .stationary,
            .canJoinAllSpaces,
            .ignoresCycle
        ]
    } else {
        level = .statusBar
        collectionBehavior = [
            .fullScreenAuxiliary,
            .canJoinAllSpaces,
            .ignoresCycle
        ]
    }

    isOpaque = false
    backgroundColor = .clear
    hasShadow = false
    isMovable = false
}
```

- [ ] **Step 2: Build and verify**

Run: `xcodebuild -project notchi.xcodeproj -scheme notchi -configuration Debug build`
Expected: BUILD SUCCEEDED

- [ ] **Step 3: Commit**

```bash
git add notchi/NotchPanel.swift
git commit -m "feat: set island mode window level to statusBar"
```

---

### Task 5: Update NotchContentView for island mode visuals

**Files:**
- Modify: `notchi/NotchContentView.swift`

This is the main visual change. Island mode needs:
- `RoundedRectangle` clip instead of `NotchShape`
- Top padding (gap below menu bar)
- Border and shadow
- Header sprites centered in capsule

- [ ] **Step 1: Add isIslandMode computed property**

Add after the `isExpanded` computed property:

```swift
private var isIslandMode: Bool { panelManager.isIslandMode }
```

- [ ] **Step 2: Add island mode constants**

Add after `compactHeaderSpriteSpacing`:

```swift
private var islandCornerRadius: CGFloat {
    isExpanded ? 20 : 18
}

private var islandTopPadding: CGFloat {
    isIslandMode ? 5 : 0
}
```

- [ ] **Step 3: Update body clip shape**

Replace the `.clipShape(NotchShape(...))` section with:

```swift
.clipShape(
    Group {
        if isIslandMode {
            RoundedRectangle(cornerRadius: islandCornerRadius, style: .continuous)
        } else {
            NotchShape(
                topCornerRadius: topCornerRadius,
                bottomCornerRadius: bottomCornerRadius
            )
        }
    }
)
```

Note: If SwiftUI doesn't allow `Group` inside `.clipShape()`, use `@ViewBuilder` or conditional with `AnyShape`. The simplest approach is to use a custom wrapper:

Replace the `.clipShape(...)` and `.shadow(...)` modifiers with:

```swift
.if(isIslandMode) { view in
    view
        .clipShape(RoundedRectangle(cornerRadius: islandCornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: islandCornerRadius, style: .continuous)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.6), radius: isExpanded ? 12 : 8)
} else: { view in
    view
        .clipShape(NotchShape(
            topCornerRadius: topCornerRadius,
            bottomCornerRadius: bottomCornerRadius
        ))
        .shadow(
            color: isExpanded ? .black.opacity(0.7) : .clear,
            radius: 6
        )
}
```

Since SwiftUI doesn't have a built-in `.if` modifier, implement it more simply by duplicating the view content inside an `if/else`:

Replace from `.clipShape(NotchShape(` through `.shadow(` with:

```swift
.modifier(PanelClipModifier(
    isIslandMode: isIslandMode,
    islandCornerRadius: islandCornerRadius,
    topCornerRadius: topCornerRadius,
    bottomCornerRadius: bottomCornerRadius,
    isExpanded: isExpanded
))
```

And add a new private struct at the bottom of the file:

```swift
private struct PanelClipModifier: ViewModifier {
    let isIslandMode: Bool
    let islandCornerRadius: CGFloat
    let topCornerRadius: CGFloat
    let bottomCornerRadius: CGFloat
    let isExpanded: Bool

    func body(content: Content) -> some View {
        if isIslandMode {
            content
                .clipShape(RoundedRectangle(cornerRadius: islandCornerRadius, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: islandCornerRadius, style: .continuous)
                        .stroke(Color.white.opacity(0.06), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.6), radius: isExpanded ? 12 : 8)
        } else {
            content
                .clipShape(NotchShape(
                    topCornerRadius: topCornerRadius,
                    bottomCornerRadius: bottomCornerRadius
                ))
                .shadow(
                    color: isExpanded ? .black.opacity(0.7) : .clear,
                    radius: 6
                )
        }
    }
}
```

- [ ] **Step 4: Update padding for island mode**

Replace the existing `.padding(.horizontal, ...)` line:

```swift
.padding(.horizontal, isIslandMode ? 0 : (isExpanded ? cornerRadiusInsets.opened.top : cornerRadiusInsets.closed.bottom))
```

Update `.frame(maxWidth:maxHeight:alignment:)`:

```swift
.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
.padding(.top, islandTopPadding)
```

- [ ] **Step 5: Update headerRow for island mode**

In `headerRow`, island mode should use the compact multi-sprite layout (same as `!hasNotch`). Update the condition:

```swift
@ViewBuilder
private var headerRow: some View {
    if panelManager.hasNotch && !isIslandMode {
        HStack(spacing: 0) {
            Color.clear
                .frame(width: notchSize.width - cornerRadiusInsets.closed.top)

            headerSprites
                .offset(x: 15, y: -2)
                .frame(width: sideWidth)
                .opacity(isExpanded ? 0 : 1)
                .animation(.none, value: isExpanded)
        }
    } else {
        headerSprites
            .offset(y: isIslandMode ? 0 : max(-1, (notchSize.height - compactHeaderSpriteSize) / -2))
            .frame(width: isIslandMode ? nil : notchSize.width, height: isIslandMode ? 36 : notchSize.height)
            .opacity(isExpanded ? 0 : 1)
            .animation(.none, value: isExpanded)
    }
}
```

- [ ] **Step 6: Update headerSprites for island mode**

In `headerSprites`, island mode should use the compact layout regardless of hasNotch:

```swift
@ViewBuilder
private var headerSprites: some View {
    if panelManager.hasNotch && !isIslandMode {
        if let topSession = sessionStore.sortedSessions.first {
            SessionSpriteView(
                state: topSession.state,
                isSelected: true
            )
        }
    } else {
        let sessions = Array(sessionStore.sortedSessions.prefix(5))
        if !sessions.isEmpty {
            HStack(spacing: compactHeaderSpriteSpacing) {
                ForEach(sessions) { session in
                    SessionSpriteView(
                        state: session.state,
                        isSelected: session.id == sessionStore.effectiveSession?.id,
                        size: isIslandMode ? 24 : compactHeaderSpriteSize
                    )
                }
            }
        }
    }
}
```

- [ ] **Step 7: Add panelStyleDidChange observer**

Add `.onReceive` in the body to rebuild when style changes. Add after the existing `.onChange(of: sessionStore.activeSessionCount)`:

```swift
.onReceive(NotificationCenter.default.publisher(for: .panelStyleDidChange)) { _ in
    // Force geometry recalculation
    if let screen = ScreenSelector.shared.selectedScreen {
        panelManager.updateGeometry(for: screen)
    }
}
```

- [ ] **Step 8: Build and verify**

Run: `xcodebuild -project notchi.xcodeproj -scheme notchi -configuration Debug build`
Expected: BUILD SUCCEEDED

- [ ] **Step 9: Commit**

```bash
git add notchi/NotchContentView.swift
git commit -m "feat: island mode visuals - rounded clip, border, shadow, capsule header"
```

---

### Task 6: Integration test and cleanup

- [ ] **Step 1: Build full project**

Run: `xcodebuild -project notchi.xcodeproj -scheme notchi -configuration Debug build`
Expected: BUILD SUCCEEDED

- [ ] **Step 2: Remove debug print from NotchPanel.swift**

Remove the `print(hasNotch)` line from `NotchPanel.init`.

- [ ] **Step 3: Final build verification**

Run: `xcodebuild -project notchi.xcodeproj -scheme notchi -configuration Debug build`
Expected: BUILD SUCCEEDED

- [ ] **Step 4: Commit**

```bash
git add notchi/NotchPanel.swift
git commit -m "chore: remove debug print statement from NotchPanel"
```
