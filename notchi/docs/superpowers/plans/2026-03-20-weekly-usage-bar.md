# Weekly Usage Bar Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Display weekly (7-day) usage alongside the existing hourly (5-hour) usage bar, with period labels ("5h" / "7d") on each bar.

**Architecture:** The API already returns `sevenDay` in `UsageResponse` but only `fiveHour` is stored. We add a `weeklyUsage` property to `ClaudeUsageService`, pass it through to `ExpandedPanelView`, and render a second `UsageBarView` with a period label. The `UsageBarView` gets a new optional `periodLabel` parameter shown at the trailing edge of the header row.

**Tech Stack:** SwiftUI, Swift, XCTest

---

### Task 1: Store weekly usage in ClaudeUsageService

**Files:**
- Modify: `notchi/Services/ClaudeUsageService.swift:123` (add property)
- Modify: `notchi/Services/ClaudeUsageService.swift:375` (store sevenDay)
- Modify: `notchi/Services/ClaudeUsageService.swift:444` (headers fallback — no weekly data available here, leave nil)

- [ ] **Step 1: Add `weeklyUsage` property**

In `ClaudeUsageService`, add a new published property right after `currentUsage`:

```swift
var currentUsage: QuotaPeriod?
var weeklyUsage: QuotaPeriod?       // ← add this line
```

- [ ] **Step 2: Store `sevenDay` from OAuth response**

At line 375 where `currentUsage = usageResponse.fiveHour`, add:

```swift
currentUsage = usageResponse.fiveHour
weeklyUsage = usageResponse.sevenDay    // ← add this line
```

- [ ] **Step 3: Build and verify no errors**

Run: `xcodebuild -project notchi.xcodeproj -scheme notchi -configuration Debug build 2>&1 | tail -5`
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 4: Commit**

```bash
git add notchi/Services/ClaudeUsageService.swift
git commit -m "feat: store weekly usage quota from API response"
```

---

### Task 2: Add period label to UsageBarView

**Files:**
- Modify: `notchi/Views/UsageBarView.swift`

- [ ] **Step 1: Add `periodLabel` parameter**

Add a new optional parameter after the `compact` property (line 10):

```swift
var compact: Bool = false
var periodLabel: String? = nil          // ← add this line
```

- [ ] **Step 2: Display the period label in the header HStack**

In the `connectedView` computed property, inside the `HStack` block (line 64–105), right before `Spacer()` on line 96, insert the period label. Replace the block from `Spacer()` through the percentage display:

Replace this (lines 96–104):
```swift
                Spacer()
                if isLoading {
                    ProgressView()
                        .controlSize(.mini)
                } else if usage != nil {
                    Text("\(effectivePercentage)%")
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .foregroundColor(usageColor)
                }
```

With:
```swift
                Spacer()
                if isLoading {
                    ProgressView()
                        .controlSize(.mini)
                } else if usage != nil {
                    HStack(spacing: 4) {
                        Text("\(effectivePercentage)%")
                            .font(.system(size: 11, weight: .semibold, design: .monospaced))
                            .foregroundColor(usageColor)
                        if let periodLabel {
                            Text(periodLabel)
                                .font(.system(size: 10, weight: .medium, design: .monospaced))
                                .foregroundColor(TerminalColors.dimmedText)
                        }
                    }
                }
```

- [ ] **Step 3: Build and verify no errors**

Run: `xcodebuild -project notchi.xcodeproj -scheme notchi -configuration Debug build 2>&1 | tail -5`
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 4: Commit**

```bash
git add notchi/Views/UsageBarView.swift
git commit -m "feat: add optional period label to UsageBarView"
```

---

### Task 3: Wire weekly usage bar into ExpandedPanelView

**Files:**
- Modify: `notchi/Views/ExpandedPanelView.swift`

- [ ] **Step 1: Add period labels and weekly bar to `sessionPickerContent`**

In `sessionPickerContent` (lines 115–124), add `periodLabel: "5h"` to the existing `UsageBarView` and add a second one for weekly usage below it:

Replace:
```swift
                UsageBarView(
                    usage: usageService.currentUsage,
                    isLoading: usageService.isLoading,
                    error: usageService.error,
                    statusMessage: usageService.statusMessage,
                    isStale: usageService.isUsageStale,
                    recoveryAction: usageService.recoveryAction,
                    onConnect: { ClaudeUsageService.shared.connectAndStartPolling() },
                    onRetry: { ClaudeUsageService.shared.retryNow() }
                )
```

With:
```swift
                UsageBarView(
                    usage: usageService.currentUsage,
                    isLoading: usageService.isLoading,
                    error: usageService.error,
                    statusMessage: usageService.statusMessage,
                    isStale: usageService.isUsageStale,
                    recoveryAction: usageService.recoveryAction,
                    periodLabel: "5h",
                    onConnect: { ClaudeUsageService.shared.connectAndStartPolling() },
                    onRetry: { ClaudeUsageService.shared.retryNow() }
                )

                if let weeklyUsage = usageService.weeklyUsage {
                    UsageBarView(
                        usage: weeklyUsage,
                        isLoading: false,
                        error: nil,
                        statusMessage: nil,
                        isStale: usageService.isUsageStale,
                        recoveryAction: .none,
                        compact: true,
                        periodLabel: "7d"
                    )
                }
```

- [ ] **Step 2: Add period labels and weekly bar to `activityContent`**

In `activityContent` (lines 161–171), apply the same pattern:

Replace:
```swift
                UsageBarView(
                    usage: usageService.currentUsage,
                    isLoading: usageService.isLoading,
                    error: usageService.error,
                    statusMessage: usageService.statusMessage,
                    isStale: usageService.isUsageStale,
                    recoveryAction: usageService.recoveryAction,
                    compact: isActivityCollapsed,
                    onConnect: { ClaudeUsageService.shared.connectAndStartPolling() },
                    onRetry: { ClaudeUsageService.shared.retryNow() }
                )
```

With:
```swift
                UsageBarView(
                    usage: usageService.currentUsage,
                    isLoading: usageService.isLoading,
                    error: usageService.error,
                    statusMessage: usageService.statusMessage,
                    isStale: usageService.isUsageStale,
                    recoveryAction: usageService.recoveryAction,
                    compact: isActivityCollapsed,
                    periodLabel: "5h",
                    onConnect: { ClaudeUsageService.shared.connectAndStartPolling() },
                    onRetry: { ClaudeUsageService.shared.retryNow() }
                )

                if let weeklyUsage = usageService.weeklyUsage {
                    UsageBarView(
                        usage: weeklyUsage,
                        isLoading: false,
                        error: nil,
                        statusMessage: nil,
                        isStale: usageService.isUsageStale,
                        recoveryAction: .none,
                        compact: isActivityCollapsed,
                        periodLabel: "7d"
                    )
                }
```

- [ ] **Step 3: Build and verify no errors**

Run: `xcodebuild -project notchi.xcodeproj -scheme notchi -configuration Debug build 2>&1 | tail -5`
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 4: Commit**

```bash
git add notchi/Views/ExpandedPanelView.swift
git commit -m "feat: display weekly usage bar below hourly usage"
```

---

### Task 4: Run existing tests

**Files:**
- Read: `Tests/ClaudeUsageServiceTests.swift`

- [ ] **Step 1: Run existing test suite to verify nothing broke**

Run: `xcodebuild -project notchi.xcodeproj -scheme Tests -configuration Debug test 2>&1 | tail -20`
Expected: All tests pass

- [ ] **Step 2: Commit (if any test fixes needed)**

Only if changes were required to fix broken tests.
