# Sleep Inducer - Complete Technical Documentation

---

## Table of Contents

1. [Architecture Overview](#1-architecture-overview)
2. [Data Flow Diagram](#2-data-flow-diagram)
3. [Apple Frameworks Used](#3-apple-frameworks-used)
4. [Project Structure](#4-project-structure)
5. [Shared Layer](#5-shared-layer)
   - 5.1 AppGroupConstants
   - 5.2 SharedSessionStore
   - 5.3 ShieldManager
6. [Data Models](#6-data-models)
   - 6.1 StrictnessMode
   - 6.2 ScheduleMode & RecurringSchedule
   - 6.3 SleepSession
7. [ViewModels](#7-viewmodels)
   - 7.1 AuthorizationViewModel
   - 7.2 SessionViewModel
   - 7.3 ScheduleViewModel
   - 7.4 AllowedAppsViewModel
8. [Views](#8-views)
   - 8.1 SleepInducerApp (Entry Point)
   - 8.2 ContentView (Root Router)
   - 8.3 HomeView (Dashboard)
   - 8.4 ManualSessionView
   - 8.5 ScheduleSetupView
   - 8.6 AllowedAppsView
   - 8.7 ActiveSessionView
   - 8.8 SettingsView
9. [UI Components](#9-ui-components)
   - 9.1 SleepButton
   - 9.2 CountdownTimerView
   - 9.3 GlowingMoonIcon
10. [Theme System](#10-theme-system)
11. [DeviceActivityMonitor Extension](#11-deviceactivitymonitor-extension)
12. [Xcode Project Configuration](#12-xcode-project-configuration)
13. [Complete Function Reference](#13-complete-function-reference)
14. [Session Lifecycle Walkthrough](#14-session-lifecycle-walkthrough)
15. [Known Constraints & Notes](#15-known-constraints--notes)

---

## 1. Architecture Overview

Sleep Inducer uses **MVVM** (Model-View-ViewModel) architecture with two process targets:

```
┌─────────────────────────────────────────────────────┐
│                    iOS Device                        │
│                                                     │
│  ┌──────────────────────┐  ┌──────────────────────┐ │
│  │   SleepInducer App   │  │  SleepInducerMonitor │ │
│  │   (Main Process)     │  │  (Extension Process) │ │
│  │                      │  │                      │ │
│  │  Views ←→ ViewModels │  │  DeviceActivity      │ │
│  │           ↕          │  │  Monitor subclass    │ │
│  │     Shared Layer     │  │       ↕              │ │
│  │     (read/write)     │  │  Shared Layer        │ │
│  │           ↕          │  │  (read/write)        │ │
│  └─────────┬────────────┘  └──────────┬───────────┘ │
│            │                          │              │
│            └──────────┬───────────────┘              │
│                       ↕                              │
│            ┌────────────────────┐                    │
│            │  App Group         │                    │
│            │  UserDefaults      │                    │
│            │  (shared storage)  │                    │
│            └────────────────────┘                    │
└─────────────────────────────────────────────────────┘
```

**Why two processes?** Apple's DeviceActivityMonitor extension runs as a separate system-managed process. It activates/deactivates shields even if the main app is force-quit. This is critical for strict mode enforcement.

**Key principle:** `ManagedSettingsStore` settings persist independently of either process. Once shields are written, they remain active until explicitly cleared. The extension's `intervalDidEnd` is the guaranteed cleanup mechanism.

---

## 2. Data Flow Diagram

### Starting a Manual Session
```
User taps "Start" in ManualSessionView
        │
        ▼
SessionViewModel.startManualSession(durationMinutes:, strictness:)
        │
        ├──→ SleepSession.manual() creates session model
        │
        ▼
SessionViewModel.activateSession(_:)
        │
        ├──→ SharedSessionStore.saveSession()        → App Group UserDefaults
        ├──→ SharedSessionStore.loadAllowedApps()     ← App Group UserDefaults
        ├──→ ShieldManager.activateShield(allowing:)  → ManagedSettingsStore
        └──→ DeviceActivityCenter.startMonitoring()   → System schedules callback
                                                           │
                                                           ▼
                                          SleepInducerMonitor.intervalDidEnd()
                                                           │
                                                           ├──→ store.clearAllSettings()
                                                           └──→ SharedSessionStore.clearSession()
```

### Cancelling a Flexible Session
```
User taps "Cancel Session"
        │
        ▼
SessionViewModel.beginCancel()
        │
        ├──→ Sets isCancelling = true
        ├──→ Sets cancelCountdown = 30
        └──→ Starts 1-second repeating Timer
                    │
                    ▼ (every second)
              cancelCountdown -= 1
                    │
            ┌───────┴─────────┐
            │                 │
     countdown > 0      countdown <= 0
     (keep ticking)           │
            │                 ▼
            │     SessionViewModel.executeCancel()
            │                 │
            │                 ├──→ ShieldManager.deactivateShield()
            │                 ├──→ DeviceActivityCenter.stopMonitoring()
            │                 └──→ SharedSessionStore.clearSession()
            │
     User taps "Keep Sleeping"
            │
            ▼
  SessionViewModel.abortCancel()
            │
            ├──→ isCancelling = false
            ├──→ cancelCountdown = 30
            └──→ Timer invalidated
```

---

## 3. Apple Frameworks Used

| Framework | Import | Purpose |
|-----------|--------|---------|
| **FamilyControls** | `import FamilyControls` | Authorization (`AuthorizationCenter`), app selection (`FamilyActivitySelection`, `FamilyActivityPicker`) |
| **ManagedSettings** | `import ManagedSettings` | Blocking apps (`ManagedSettingsStore`, `shield.applications`, `shield.applicationCategories`, `shield.webDomains`) |
| **DeviceActivity** | `import DeviceActivity` | Scheduling callbacks (`DeviceActivityCenter`, `DeviceActivityMonitor`, `DeviceActivitySchedule`, `DeviceActivityName`) |

### How They Work Together
1. **FamilyControls** grants permission and lets the user pick which apps to allow
2. **ManagedSettings** enforces the actual block — it writes shield rules to the system that persist independently
3. **DeviceActivity** schedules time-based callbacks so the extension can activate/deactivate shields at the right time

---

## 4. Project Structure

```
SleepInducer/
├── project.yml                            # XcodeGen specification
├── SleepInducer.xcodeproj/                # Generated Xcode project
│
├── SleepInducer/                          # ── Main App Target ──
│   ├── SleepInducerApp.swift              # @main entry point
│   ├── SleepInducer.entitlements          # App Groups + FamilyControls
│   │
│   ├── Models/
│   │   ├── StrictnessMode.swift           # .strict / .flexible enum
│   │   ├── ScheduleMode.swift             # .manual / .recurring + RecurringSchedule
│   │   └── SleepSession.swift             # Core session data model
│   │
│   ├── ViewModels/
│   │   ├── AuthorizationViewModel.swift   # Screen Time auth state
│   │   ├── SessionViewModel.swift         # Session lifecycle orchestrator
│   │   ├── ScheduleViewModel.swift        # Recurring schedule management
│   │   └── AllowedAppsViewModel.swift     # App selection persistence
│   │
│   ├── Views/
│   │   ├── ContentView.swift              # Root router view
│   │   ├── HomeView.swift                 # Dashboard with navigation cards
│   │   ├── ManualSessionView.swift        # Duration + mode picker + start
│   │   ├── ScheduleSetupView.swift        # Recurring time pickers
│   │   ├── AllowedAppsView.swift          # Apple FamilyActivityPicker
│   │   ├── ActiveSessionView.swift        # Live countdown during block
│   │   ├── SettingsView.swift             # Defaults + emergency reset
│   │   └── Components/
│   │       ├── SleepButton.swift          # Reusable styled action button
│   │       ├── CountdownTimerView.swift   # Circular progress ring
│   │       └── GlowingMoonIcon.swift      # Animated decorative icon
│   │
│   └── Theme/
│       └── SleepTheme.swift               # Colors, gradients, card modifier
│
├── Shared/                                # ── Shared Between Both Targets ──
│   ├── AppGroupConstants.swift            # App Group ID + UserDefaults keys
│   ├── SharedSessionStore.swift           # CRUD for session/apps/schedule/strictness
│   └── ShieldManager.swift                # ManagedSettingsStore apply/remove
│
└── SleepInducerMonitor/                   # ── Extension Target ──
    ├── SleepInducerMonitor.swift          # DeviceActivityMonitor subclass
    ├── SleepInducerMonitor.entitlements   # App Groups + FamilyControls
    └── Info.plist                          # Extension point declaration
```

**Target membership:**
- `SleepInducer/` files → main app target only
- `Shared/` files → **both** main app and extension targets
- `SleepInducerMonitor/` files → extension target only

---

## 5. Shared Layer

These three files are compiled into **both** the main app and the extension. They form the bridge for cross-process communication.

### 5.1 AppGroupConstants

**File:** `Shared/AppGroupConstants.swift`

A caseless enum (cannot be instantiated) that centralizes all App Group configuration.

| Member | Type | Value | Purpose |
|--------|------|-------|---------|
| `suiteName` | `String` | `"group.com.sleepinducer.shared"` | The App Group container identifier. Must match the entitlements in both targets. |
| `Keys.activeSession` | `String` | `"activeSession"` | UserDefaults key for the current `SleepSession` (JSON data). |
| `Keys.allowedApps` | `String` | `"allowedApps"` | UserDefaults key for the `FamilyActivitySelection` (JSON data). |
| `Keys.recurringSchedule` | `String` | `"recurringSchedule"` | UserDefaults key for the `RecurringSchedule` (JSON data). |
| `Keys.defaultStrictness` | `String` | `"defaultStrictness"` | UserDefaults key for the default `StrictnessMode` raw string. |
| `sharedDefaults` | `UserDefaults` (computed) | `UserDefaults(suiteName:)` | Returns the shared UserDefaults instance for the App Group. Falls back to `.standard` if creation fails (should never happen with valid entitlements). |

**Why a caseless enum?** Prevents accidental instantiation. Acts as a pure namespace.

---

### 5.2 SharedSessionStore

**File:** `Shared/SharedSessionStore.swift`

Singleton (`SharedSessionStore.shared`) that provides typed CRUD operations over App Group UserDefaults. All data is serialized as JSON via `Codable`.

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `shared` | `SharedSessionStore` | Singleton instance. |
| `defaults` | `UserDefaults` | Private. The App Group shared defaults from `AppGroupConstants.sharedDefaults`. |
| `encoder` | `JSONEncoder` | Private. Reused encoder instance for performance. |
| `decoder` | `JSONDecoder` | Private. Reused decoder instance for performance. |

#### Functions

**`saveSession(_ session: SleepSession)`**
- Encodes the `SleepSession` to JSON data and writes it to UserDefaults under the `activeSession` key.
- Called by `SessionViewModel.activateSession(_:)` when a new session starts.
- Silently fails if encoding fails (should never happen since `SleepSession` is `Codable`).

**`loadSession() -> SleepSession?`**
- Reads JSON data from the `activeSession` key and decodes it to `SleepSession`.
- Returns `nil` if no data exists or decoding fails.
- Called by `SessionViewModel.loadExistingSession()` on init (app launch / foreground).

**`clearSession()`**
- Removes the `activeSession` key from UserDefaults entirely.
- Called when a session ends naturally, is cancelled, or emergency reset.
- Also called by the extension in `intervalDidEnd`.

**`saveAllowedApps(_ selection: FamilyActivitySelection)`**
- Encodes the `FamilyActivitySelection` (Apple's Codable type containing opaque app/category tokens) and stores it.
- Called by `AllowedAppsViewModel.save()` whenever the user changes their app selection.

**`loadAllowedApps() -> FamilyActivitySelection`**
- Decodes and returns the stored selection. Returns an empty `FamilyActivitySelection()` if nothing is stored.
- Called by `SessionViewModel` when activating shields and by the extension in `intervalDidStart`.
- **Never returns nil** — always returns a valid (possibly empty) selection.

**`saveSchedule(_ schedule: RecurringSchedule)`**
- Encodes and persists the recurring schedule configuration.
- Called by `ScheduleViewModel.save()`.

**`loadSchedule() -> RecurringSchedule?`**
- Returns the stored recurring schedule, or `nil` if none exists.
- Called by `ScheduleViewModel.init()`.

**`clearSchedule()`**
- Removes the recurring schedule from UserDefaults.
- Not currently called by any view but available for future use.

**`saveDefaultStrictness(_ mode: StrictnessMode)`**
- Stores the raw string value (`"strict"` or `"flexible"`) of the user's preferred default mode.
- Called by `SettingsView` when the segmented control changes.

**`loadDefaultStrictness() -> StrictnessMode`**
- Returns the stored default, or `.flexible` if none is set.
- Called by `ManualSessionView` to pre-populate the strictness picker on init.

---

### 5.3 ShieldManager

**File:** `Shared/ShieldManager.swift`

Singleton that wraps `ManagedSettingsStore` for applying and removing app shields.

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `shared` | `ShieldManager` | Singleton instance. |
| `store` | `ManagedSettingsStore` | Private. Apple's persistent settings store. Writes survive app termination. |

#### Functions

**`activateShield(allowing selection: FamilyActivitySelection)`**
- Extracts `applicationTokens` (Set of opaque app identifiers) and `categoryTokens` (Set of opaque category identifiers) from the selection.
- Sets `store.shield.applications = .all(except: applications)` — blocks every app except the allowed ones.
- Sets `store.shield.applicationCategories = .all(except: categories)` — blocks every app category except allowed categories.
- Sets `store.shield.webDomains = .all()` — blocks all web browsing (Safari, in-app browsers).
- **Critical:** These settings persist in the system even if the app process is killed. Only `clearAllSettings()` removes them.

**`deactivateShield()`**
- Calls `store.clearAllSettings()` which removes all shield rules.
- Apps become accessible again immediately.
- Called by `SessionViewModel` on session end/cancel/reset and by the extension in `intervalDidEnd`.

---

## 6. Data Models

### 6.1 StrictnessMode

**File:** `SleepInducer/Models/StrictnessMode.swift`

An enum representing how strictly the session blocks apps.

```swift
enum StrictnessMode: String, Codable, CaseIterable, Identifiable
```

| Case | Raw Value | Behavior |
|------|-----------|----------|
| `.strict` | `"strict"` | No cancel button shown. Shields persist until the timer expires. Only emergency reset can override. |
| `.flexible` | `"flexible"` | Cancel button shown with a mandatory 30-second countdown delay before shields are removed. |

#### Computed Properties

| Property | Type | `.strict` | `.flexible` |
|----------|------|-----------|-------------|
| `id` | `String` | `"strict"` | `"flexible"` |
| `displayName` | `String` | `"Strict"` | `"Flexible"` |
| `description` | `String` | `"Cannot cancel until time is up"` | `"Cancel with a 30-second delay"` |

**Protocol conformances:**
- `String, RawRepresentable` — enables storage as a plain string in UserDefaults
- `Codable` — enables JSON serialization as part of `SleepSession`
- `CaseIterable` — enables `ForEach(StrictnessMode.allCases)` in picker views
- `Identifiable` — enables use in SwiftUI `ForEach` without explicit `id:` parameter

---

### 6.2 ScheduleMode & RecurringSchedule

**File:** `SleepInducer/Models/ScheduleMode.swift`

#### ScheduleMode (Enum)

```swift
enum ScheduleMode: Codable, Equatable
```

Discriminated union representing how a session was created.

| Case | Associated Values | Usage |
|------|-------------------|-------|
| `.manual(durationMinutes: Int)` | Duration in minutes (e.g., 30, 60, 120) | Created when user taps "Start" in ManualSessionView |
| `.recurring(startHour: Int, startMinute: Int, endHour: Int, endMinute: Int)` | 24-hour clock components | Created by the nightly schedule system |

This enum is stored inside `SleepSession` to track the origin of each session.

#### RecurringSchedule (Struct)

```swift
struct RecurringSchedule: Codable, Equatable
```

Represents the user's configured nightly schedule. Persisted independently from `SleepSession`.

| Property | Type | Description |
|----------|------|-------------|
| `isEnabled` | `Bool` | Whether the schedule is active. When `false`, monitoring is stopped. |
| `startHour` | `Int` | Bedtime hour (0-23). Default: `22` (10 PM). |
| `startMinute` | `Int` | Bedtime minute (0-59). Default: `0`. |
| `endHour` | `Int` | Wake hour (0-23). Default: `7` (7 AM). |
| `endMinute` | `Int` | Wake minute (0-59). Default: `0`. |
| `strictness` | `StrictnessMode` | Mode for scheduled sessions. Default: `.flexible`. |

| Computed Property | Type | Description |
|-------------------|------|-------------|
| `startDate` | `Date` | A `Date` object for today with `startHour:startMinute`. Used by DatePicker binding. |
| `endDate` | `Date` | A `Date` object for today with `endHour:endMinute`. Used by DatePicker binding. |

| Static Property | Description |
|-----------------|-------------|
| `.default` | `RecurringSchedule(isEnabled: false, startHour: 22, startMinute: 0, endHour: 7, endMinute: 0, strictness: .flexible)` |

---

### 6.3 SleepSession

**File:** `SleepInducer/Models/SleepSession.swift`

The core data model representing an active or completed sleep session.

```swift
struct SleepSession: Codable, Identifiable, Equatable
```

#### Stored Properties

| Property | Type | Mutable | Description |
|----------|------|---------|-------------|
| `id` | `UUID` | `let` | Unique identifier for the session. Generated on creation. |
| `mode` | `ScheduleMode` | `let` | Whether this was a manual or recurring session. |
| `strictness` | `StrictnessMode` | `let` | Strict or flexible mode. |
| `startedAt` | `Date` | `let` | Timestamp when the session was created/started. |
| `endsAt` | `Date` | `let` | Timestamp when the session should automatically end. |
| `isActive` | `Bool` | `var` | Whether the session is currently blocking apps. |

#### Computed Properties

**`remainingTime: TimeInterval`**
- Returns `max(0, endsAt - now)`. The number of seconds remaining until the session ends.
- Returns `0` if the session is expired. Never negative.

**`isExpired: Bool`**
- Returns `true` if the current time is at or past `endsAt`.
- Used by `SessionViewModel.checkExpiry()` to detect when a session should auto-end.

**`durationFormatted: String`**
- Returns a human-readable string of the total session duration (not remaining time).
- Format: `"2h"`, `"30m"`, `"1h 30m"`.
- Calculated from `endsAt - startedAt`.

#### Static Factory Method

**`static func manual(durationMinutes: Int, strictness: StrictnessMode) -> SleepSession`**
- Creates a new `SleepSession` for a manual (one-off) session.
- Sets `startedAt` to `Date.now`.
- Computes `endsAt` as `now + (durationMinutes * 60)` seconds.
- Sets `isActive = true`.
- Sets `mode = .manual(durationMinutes:)`.

---

## 7. ViewModels

All ViewModels are `@MainActor` (UI thread only) and `ObservableObject` (SwiftUI reactive).

### 7.1 AuthorizationViewModel

**File:** `SleepInducer/ViewModels/AuthorizationViewModel.swift`

Manages the FamilyControls authorization flow. This is the first gate — the app cannot function without Screen Time permission.

#### Published Properties

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `isAuthorized` | `Bool` | `false` | Whether the user has granted Screen Time access. |
| `isLoading` | `Bool` | `false` | Whether an authorization request is in flight. |
| `errorMessage` | `String?` | `nil` | Error text to display if authorization fails. |

#### Functions

**`init()`**
- Calls `checkCurrentStatus()` immediately to sync with the system's current auth state.

**`checkCurrentStatus()`**
- Reads `AuthorizationCenter.shared.authorizationStatus` (a synchronous property).
- Sets `isAuthorized = true` only if status is `.approved`.
- This handles the case where the user previously granted permission — the app won't re-prompt.

**`requestAuthorization() async`**
- Sets `isLoading = true`, clears any previous error.
- Calls `AuthorizationCenter.shared.requestAuthorization(for: .individual)`.
  - `.individual` means this is a personal device (not parental controls).
  - This triggers the system Screen Time authorization prompt.
- On success: sets `isAuthorized = true`.
- On failure: sets `errorMessage` with instructions, `isAuthorized = false`.
- Always sets `isLoading = false` at the end.

---

### 7.2 SessionViewModel

**File:** `SleepInducer/ViewModels/SessionViewModel.swift`

The central orchestrator for session lifecycle. This is the most complex ViewModel.

#### Published Properties

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `activeSession` | `SleepSession?` | `nil` | The currently active session. `nil` = no session running. |
| `isCancelling` | `Bool` | `false` | Whether the 30-second cancel countdown is active. |
| `cancelCountdown` | `Int` | `30` | Seconds remaining in the cancel countdown. |

#### Private Properties

| Property | Type | Description |
|----------|------|-------------|
| `store` | `SharedSessionStore` | Reference to the shared data store singleton. |
| `shieldManager` | `ShieldManager` | Reference to the shield manager singleton. |
| `activityCenter` | `DeviceActivityCenter` | Apple's API for registering/unregistering DeviceActivity monitoring schedules. |
| `cancelTimer` | `Timer?` | The repeating 1-second timer for the cancel countdown. `nil` when not cancelling. |

#### Computed Properties

**`hasActiveSession: Bool`**
- Returns `activeSession?.isActive == true`.
- Used by `ContentView` to decide whether to show the active session screen or the home screen.

#### Public Functions

**`init()`**
- Calls `loadExistingSession()` to restore any session that was active before the app was killed/backgrounded.

**`startManualSession(durationMinutes: Int, strictness: StrictnessMode)`**
- Creates a `SleepSession` via the `.manual()` factory.
- Calls `activateSession(_:)` to persist, shield, and monitor.
- Called from `ManualSessionView` when the user taps "Start Sleep Session".

**`beginCancel()`**
- Guard: only proceeds if `activeSession?.strictness == .flexible`. No-op for strict sessions.
- Sets `isCancelling = true` and `cancelCountdown = 30`.
- Creates a `Timer.scheduledTimer` that fires every 1 second.
  - Each tick: decrements `cancelCountdown` by 1 on the main actor.
  - When `cancelCountdown <= 0`: invalidates the timer and calls `executeCancel()`.
- The timer uses `[weak self]` to avoid retain cycles. If `self` is deallocated, the timer auto-invalidates.

**`abortCancel()`**
- Resets `isCancelling = false` and `cancelCountdown = 30`.
- Invalidates and nils the cancel timer.
- Called when user taps "Keep Sleeping" during the cancel countdown.

**`emergencyReset()`**
- The nuclear option. Immediately:
  1. Invalidates any cancel timer.
  2. Calls `shieldManager.deactivateShield()` — removes all app blocks instantly.
  3. Calls `stopMonitoring()` — unregisters the DeviceActivity schedule.
  4. Calls `store.clearSession()` — removes the session from shared storage.
  5. Sets `activeSession = nil` and `isCancelling = false`.
- Called from `SettingsView` after the user confirms the alert.

**`checkExpiry()`**
- If `activeSession` exists and `isExpired` is true, calls `endSession()`.
- Called every 5 seconds by a Timer in `ActiveSessionView`.
- This is a fallback — the primary end mechanism is the extension's `intervalDidEnd`.

#### Private Functions

**`activateSession(_ session: SleepSession)`**
- The core activation sequence:
  1. `store.saveSession(session)` — persists to App Group UserDefaults so the extension can read it.
  2. `activeSession = session` — updates the published property, triggering UI navigation to `ActiveSessionView`.
  3. `store.loadAllowedApps()` — reads the user's allowed app selection.
  4. `shieldManager.activateShield(allowing:)` — writes shield rules to `ManagedSettingsStore`. **Apps are now blocked.**
  5. `startMonitoring(until: session.endsAt)` — registers a DeviceActivity schedule so the extension fires `intervalDidEnd` at the right time.

**`executeCancel()`**
- Resets `isCancelling = false` and nils the timer.
- Calls `endSession()`.

**`endSession()`**
- The standard cleanup sequence:
  1. `shieldManager.deactivateShield()` — clears all shield rules. **Apps are now unblocked.**
  2. `stopMonitoring()` — unregisters the DeviceActivity schedule.
  3. `store.clearSession()` — removes session from shared storage.
  4. `activeSession = nil` — triggers UI navigation back to home.

**`loadExistingSession()`**
- Called on `init()`.
- Tries to load a session from the shared store.
- If found and expired: calls `endSession()` (cleanup shields just in case).
- If found and still active: restores `activeSession` so the UI shows `ActiveSessionView`.
- If not found: no-op (normal state when no session is running).

**`startMonitoring(until endDate: Date)`**
- Creates a `DeviceActivityName("sleepSession")` identifier.
- Creates a `DeviceActivitySchedule` with:
  - `intervalStart`: current time components (hour, minute, second).
  - `intervalEnd`: end time components.
  - `repeats: false` — one-shot schedule.
- Calls `activityCenter.startMonitoring(activityName, during: schedule)`.
- If this fails (e.g., invalid schedule), it prints the error but doesn't crash.

**`stopMonitoring()`**
- Calls `activityCenter.stopMonitoring([DeviceActivityName("sleepSession")])`.
- Unregisters the monitoring schedule so the extension won't fire.

---

### 7.3 ScheduleViewModel

**File:** `SleepInducer/ViewModels/ScheduleViewModel.swift`

Manages the recurring nightly schedule configuration.

#### Published Properties

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `schedule` | `RecurringSchedule` | Loaded from store or `.default` | The current schedule configuration. |

#### Private Properties

| Property | Type | Description |
|----------|------|-------------|
| `store` | `SharedSessionStore` | Shared data store. |
| `activityCenter` | `DeviceActivityCenter` | For registering/unregistering repeating schedules. |

#### Computed Properties (DatePicker Bindings)

**`startTime: Date` (get/set)**
- **Get:** Returns `schedule.startDate` (a Date with today's date and the stored hour/minute).
- **Set:** Extracts hour and minute from the new Date and updates `schedule.startHour` / `schedule.startMinute`.
- Bound to the "Bedtime" DatePicker in `ScheduleSetupView`.

**`endTime: Date` (get/set)**
- **Get:** Returns `schedule.endDate`.
- **Set:** Extracts hour and minute and updates `schedule.endHour` / `schedule.endMinute`.
- Bound to the "Wake Up" DatePicker.

#### Functions

**`init()`**
- Loads the schedule from `store.loadSchedule()`. Falls back to `RecurringSchedule.default` if none exists.

**`save()`**
- Persists `schedule` to the shared store via `store.saveSchedule(schedule)`.
- If `schedule.isEnabled`: calls `startScheduleMonitoring()` to register with the system.
- If `!schedule.isEnabled`: calls `stopScheduleMonitoring()` to unregister.
- Called when user taps "Save Schedule" in `ScheduleSetupView`.

**`toggleEnabled()`**
- Flips `schedule.isEnabled` and calls `save()`.
- Not currently used by the UI (the toggle directly binds to `schedule.isEnabled`), but available for programmatic use.

**Private: `startScheduleMonitoring()`**
- Creates `DeviceActivityName("nightlySchedule")`.
- Creates a `DeviceActivitySchedule` with:
  - `intervalStart`: `DateComponents(hour: startHour, minute: startMinute)`.
  - `intervalEnd`: `DateComponents(hour: endHour, minute: endMinute)`.
  - `repeats: true` — fires every day.
- Registers with `activityCenter.startMonitoring(...)`.
- The extension's `intervalDidStart` fires at bedtime; `intervalDidEnd` fires at wake time.

**Private: `stopScheduleMonitoring()`**
- Unregisters `DeviceActivityName("nightlySchedule")` from the activity center.

---

### 7.4 AllowedAppsViewModel

**File:** `SleepInducer/ViewModels/AllowedAppsViewModel.swift`

Manages the user's allowed apps selection. The simplest ViewModel.

#### Published Properties

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `activitySelection` | `FamilyActivitySelection` | Loaded from store | The set of apps/categories the user has chosen to keep accessible during sleep. |

#### Functions

**`init()`**
- Loads the previously saved selection from `store.loadAllowedApps()`.

**`save()`**
- Persists the current `activitySelection` to the shared store.
- Called by `AllowedAppsView` whenever `activitySelection` changes (via `.onChange` modifier).

---

## 8. Views

### 8.1 SleepInducerApp (Entry Point)

**File:** `SleepInducer/SleepInducerApp.swift`

```swift
@main
struct SleepInducerApp: App
```

- The `@main` attribute marks this as the application entry point.
- Imports `FamilyControls` at the app level to ensure the framework is linked.
- Creates a single `WindowGroup` containing `ContentView`.
- No app-level state management — all state lives in ViewModels created by views.

---

### 8.2 ContentView (Root Router)

**File:** `SleepInducer/Views/ContentView.swift`

The root view that decides which screen to show based on app state.

#### State Objects

| Property | Type | Description |
|----------|------|-------------|
| `authVM` | `AuthorizationViewModel` | Owns the authorization state. Created once, lives for app lifetime. |
| `sessionVM` | `SessionViewModel` | Owns the session state. Created once, lives for app lifetime. |

#### Routing Logic

```
if !authVM.isAuthorized → authorizationView (inline)
else if sessionVM.hasActiveSession → ActiveSessionView
else → NavigationStack { HomeView }
```

**Authorization View** (inline private computed property):
- Shows `GlowingMoonIcon`, app title, description text.
- Shows error message (red text) if `authVM.errorMessage` is set.
- Shows a "Grant Access" `SleepButton` that calls `authVM.requestAuthorization()` asynchronously.
- Button is disabled and dimmed while `authVM.isLoading`.

**Full-screen styling:**
- `SleepTheme.backgroundGradient` fills the entire screen via `.ignoresSafeArea()`.
- `.preferredColorScheme(.dark)` forces dark mode system-wide for this app.

---

### 8.3 HomeView (Dashboard)

**File:** `SleepInducer/Views/HomeView.swift`

The main dashboard shown when authorized and no session is active.

#### Parameters

| Property | Type | Description |
|----------|------|-------------|
| `sessionVM` | `SessionViewModel` (`@ObservedObject`) | Passed from `ContentView`. Forwarded to child views. |

#### Layout Structure

1. **Header**: `GlowingMoonIcon` + "Sleep Inducer" title + "Time to wind down" subtitle.

2. **Start Now Card** (`NavigationLink` → `ManualSessionView`):
   - Icon: `moon.zzz.fill`
   - Label: "Start Now" / "Block apps for a set duration"
   - Passes `sessionVM` to `ManualSessionView`.

3. **Nightly Schedule Card** (`NavigationLink` → `ScheduleSetupView`):
   - Icon: `calendar.badge.clock`
   - Label: "Nightly Schedule" / "Set a recurring bedtime block"

4. **Allowed Apps Card** (`NavigationLink` → `AllowedAppsView`):
   - Icon: `checkmark.shield.fill`
   - Label: "Allowed Apps" / "Choose apps that stay accessible"

5. **Settings Card** (`NavigationLink` → `SettingsView`):
   - Icon: `gearshape.fill`
   - Label: "Settings" / "Defaults and emergency reset"
   - Passes `sessionVM` for emergency reset functionality.

All cards use the `.sleepCard()` modifier for consistent styling.
`.navigationBarHidden(true)` hides the default navigation bar since the view has its own header.

---

### 8.4 ManualSessionView

**File:** `SleepInducer/Views/ManualSessionView.swift`

Lets the user configure and start a one-off sleep session.

#### Parameters & State

| Property | Type | Description |
|----------|------|-------------|
| `sessionVM` | `SessionViewModel` (`@ObservedObject`) | For calling `startManualSession`. |
| `dismiss` | `DismissAction` (`@Environment`) | For programmatic back navigation (not currently used but available). |
| `selectedDuration` | `Int` (`@State`) | Selected duration in minutes. Default: `60`. |
| `strictness` | `StrictnessMode` (`@State`) | Selected mode. Default: loaded from `SharedSessionStore.loadDefaultStrictness()`. |

#### Duration Options

Defined as a private array of tuples:

| Label | Minutes |
|-------|---------|
| "30m" | 30 |
| "1h" | 60 |
| "2h" | 120 |
| "4h" | 240 |
| "6h" | 360 |
| "8h" | 480 |

#### Layout Structure

1. **Duration Picker**: A 3-column `LazyVGrid`. Each cell is a button. Selected cell shows `SleepTheme.buttonGradient` background; unselected shows `Color.white.opacity(0.08)`.

2. **Strictness Picker**: Two radio-button-style rows, one per `StrictnessMode`. Each shows:
   - Mode name + description text
   - Checkmark circle icon (filled when selected)
   - Indigo border when selected

3. **Start Button**: `SleepButton("Start Sleep Session", icon: "moon.fill")` that calls `sessionVM.startManualSession(durationMinutes: selectedDuration, strictness: strictness)`. This triggers `ContentView` to switch to `ActiveSessionView`.

---

### 8.5 ScheduleSetupView

**File:** `SleepInducer/Views/ScheduleSetupView.swift`

Configures the recurring nightly schedule.

#### State

| Property | Type | Description |
|----------|------|-------------|
| `viewModel` | `ScheduleViewModel` (`@StateObject`) | Owns the schedule state. Created fresh each time the view appears. |
| `dismiss` | `DismissAction` | For navigating back after save. |

#### Layout Structure

1. **Enable Toggle Card**: HStack with schedule description + `Toggle` bound to `viewModel.schedule.isEnabled`.

2. **Time Pickers** (shown only when enabled, with animation):
   - "Bedtime" label + wheel-style `DatePicker` bound to `viewModel.startTime`.
   - Divider.
   - "Wake Up" label + wheel-style `DatePicker` bound to `viewModel.endTime`.

3. **Strictness Picker** (shown only when enabled):
   - Segmented `Picker` bound to `viewModel.schedule.strictness`.

4. **Save Button**: Calls `viewModel.save()` then `dismiss()` to go back.

The enabled/disabled toggle animates the appearance/disappearance of time pickers with `.animation(.easeInOut(duration: 0.3))`.

---

### 8.6 AllowedAppsView

**File:** `SleepInducer/Views/AllowedAppsView.swift`

Wraps Apple's built-in `FamilyActivityPicker` for selecting which apps remain accessible.

#### State

| Property | Type | Description |
|----------|------|-------------|
| `viewModel` | `AllowedAppsViewModel` (`@StateObject`) | Manages the `FamilyActivitySelection`. |

#### Layout Structure

1. **Instruction text**: "These apps will remain accessible during sleep sessions." + "Phone and Messages are recommended."

2. **`FamilyActivityPicker(selection:)`**: Apple's native multi-select app picker UI. Shows all installed apps with checkmarks. Bound to `viewModel.activitySelection`.

3. **Auto-save**: `.onChange(of: viewModel.activitySelection)` calls `viewModel.save()` whenever the selection changes. No explicit save button needed.

**Note:** `FamilyActivityPicker` is an opaque Apple-provided view. Its internal appearance cannot be customized. It handles its own scrolling, searching, and category grouping.

---

### 8.7 ActiveSessionView

**File:** `SleepInducer/Views/ActiveSessionView.swift`

Shown full-screen when a sleep session is active. Displays the countdown and optional cancel controls.

#### Parameters

| Property | Type | Description |
|----------|------|-------------|
| `sessionVM` | `SessionViewModel` (`@ObservedObject`) | The session state. |

#### Layout Structure (when `activeSession` exists)

1. **Moon Icon**: `moon.zzz.fill` in warm gold, size 44.

2. **Title**: "Sleep Mode Active".

3. **Countdown Ring**: `CountdownTimerView` with `endsAt` and `totalDuration` from the session.

4. **Session Info**: Two labels showing:
   - Duration formatted (e.g., "2h")
   - Mode name + lock icon (locked for strict, unlocked for flexible)

5. **Cancel Section** (conditional):
   - **Strict mode**: Shows text "Strict mode - session cannot be cancelled". No button.
   - **Flexible mode, not cancelling**: Shows "Cancel Session" danger button + "30-second delay" hint.
   - **Flexible mode, cancelling**: Shows "Cancelling in Xs..." text + progress bar + "Keep Sleeping" button.

#### Timer

- `.onReceive(Timer.publish(every: 5, ...))` calls `sessionVM.checkExpiry()` every 5 seconds.
- This is a safety net to auto-end the session from the app side if the extension callback is delayed.

---

### 8.8 SettingsView

**File:** `SleepInducer/Views/SettingsView.swift`

App settings and emergency controls.

#### Parameters & State

| Property | Type | Description |
|----------|------|-------------|
| `sessionVM` | `SessionViewModel` (`@ObservedObject`) | For emergency reset. |
| `defaultStrictness` | `StrictnessMode` (`@State`) | Current default mode. Loaded from store on init. |
| `showResetConfirmation` | `Bool` (`@State`) | Controls the confirmation alert. |

#### Layout Structure

1. **Default Mode Card**: Segmented picker for `StrictnessMode`. `.onChange` saves to store immediately. Shows the mode's description below.

2. **Emergency Reset Card**: Warning text + red "Emergency Reset" button. Tapping shows a confirmation `.alert`. Confirming calls `sessionVM.emergencyReset()`.

3. **About Card**: Static descriptive text about the app.

---

## 9. UI Components

### 9.1 SleepButton

**File:** `SleepInducer/Views/Components/SleepButton.swift`

A reusable full-width action button with three visual styles.

#### Init Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `title` | `String` | (required) | Button label text. |
| `icon` | `String?` | `nil` | Optional SF Symbol name shown before the title. |
| `style` | `Style` | `.primary` | Visual variant. |
| `action` | `() -> Void` | (required) | Closure executed on tap. |

#### Styles

| Style | Background | Text Color |
|-------|------------|------------|
| `.primary` | `SleepTheme.buttonGradient` (indigo → lavender) | White |
| `.secondary` | `Color.white.opacity(0.1)` (translucent) | `SleepTheme.lavender` |
| `.danger` | `SleepTheme.dangerRed.opacity(0.8)` (semi-transparent red) | White |

#### Visual Properties
- Full width: `.frame(maxWidth: .infinity)`
- Vertical padding: 16pt
- Corner radius: 14pt
- Font: `.title3.weight(.semibold)` for both icon and text
- Icon and text spaced 8pt apart

---

### 9.2 CountdownTimerView

**File:** `SleepInducer/Views/Components/CountdownTimerView.swift`

A circular progress ring that counts down to the session end time.

#### Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| `endsAt` | `Date` | The absolute time the session ends. |
| `totalDuration` | `TimeInterval` | Total session duration in seconds (used to calculate progress percentage). |

#### How It Works

Uses `TimelineView(.periodic(from: .now, by: 1))` which re-renders the body every 1 second. On each render:

1. Computes `rem = max(0, endsAt - now)` — remaining seconds.
2. Computes `progress = 1.0 - (rem / totalDuration)` — fraction completed (0.0 to 1.0).
3. Draws:
   - **Background ring**: Full circle, `Color.white.opacity(0.1)`, 8pt stroke, 200x200.
   - **Progress ring**: Partial circle via `.trim(from: 0, to: progress)`, `SleepTheme.buttonGradient` stroke, 8pt rounded line cap, rotated -90 degrees (starts at top). Animated with `.linear(duration: 1)`.
   - **Time text**: Formatted as `H:MM:SS` or `MM:SS` (no hours if < 1h). Monospaced font, size 40, light weight.
   - **"remaining" label**: Small caption below the time.

#### `formatTime(_ seconds: TimeInterval) -> String`
- Converts seconds to `H:MM:SS` format if hours > 0.
- Converts to `MM:SS` if under 1 hour.
- Uses zero-padded minutes and seconds.

---

### 9.3 GlowingMoonIcon

**File:** `SleepInducer/Views/Components/GlowingMoonIcon.swift`

A decorative animated moon icon used on the authorization and home screens.

#### State

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `glowing` | `Bool` (`@State`) | `false` | Toggles the glow intensity. |

#### Appearance
- SF Symbol: `moon.fill`, size 60
- Color: `SleepTheme.warmGold`
- Shadow: warm gold, oscillates between 0.2/10pt and 0.6/20pt opacity/radius
- Animation: `.easeInOut(duration: 2).repeatForever(autoreverses: true)` — continuous breathing glow

---

## 10. Theme System

**File:** `SleepInducer/Theme/SleepTheme.swift`

Caseless enum providing the app's visual constants.

### Colors

| Name | RGB | Hex (approx) | Usage |
|------|-----|---------------|-------|
| `deepNavy` | (0.05, 0.05, 0.15) | `#0D0D26` | Primary background |
| `midnightBlue` | (0.08, 0.08, 0.25) | `#141440` | Background gradient midpoint |
| `indigo` | (0.35, 0.30, 0.85) | `#594DD9` | Primary accent, button starts, selection highlights |
| `lavender` | (0.65, 0.55, 0.95) | `#A68CF2` | Secondary accent, subtitles, button ends |
| `softWhite` | (0.92, 0.90, 0.98) | `#EBE6FA` | Primary text (not pure white for softer feel) |
| `warmGold` | (1.0, 0.85, 0.40) | `#FFD966` | Moon icon, decorative accents |
| `dangerRed` | (0.90, 0.30, 0.30) | `#E64D4D` | Cancel/reset buttons, warning text |

### Gradients

| Name | Type | Colors | Direction |
|------|------|--------|-----------|
| `backgroundGradient` | `LinearGradient` | deepNavy → midnightBlue → deepNavy | Top → Bottom |
| `buttonGradient` | `LinearGradient` | indigo → lavender | Leading → Trailing |
| `cardGradient` | `LinearGradient` | white@8% → white@3% | TopLeading → BottomTrailing |

### Card Modifier

**`sleepCard()` (View extension)**

Applies to any view:
1. `.padding()` — standard padding inside the card
2. `.background(cardGradient)` — translucent white gradient
3. `.clipShape(RoundedRectangle(cornerRadius: 16))` — rounded corners
4. `.overlay(RoundedRectangle stroke)` — subtle white@10% border, 1pt

Used on all card-style containers in `HomeView`, `ScheduleSetupView`, `SettingsView`, and `ManualSessionView`.

---

## 11. DeviceActivityMonitor Extension

**File:** `SleepInducerMonitor/SleepInducerMonitor.swift`

This is a **separate process** managed by iOS. It runs outside the main app's lifecycle.

```swift
class SleepInducerMonitor: DeviceActivityMonitor
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `store` | `ManagedSettingsStore` | The same system settings store. Writes from the extension affect the same shield rules as the main app. |

#### Overridden Methods

**`intervalDidStart(for activity: DeviceActivityName)`**
- Called by iOS when a registered DeviceActivity schedule's start time is reached.
- Sequence:
  1. Calls `super.intervalDidStart(for:)`.
  2. Loads allowed apps from `SharedSessionStore.shared.loadAllowedApps()` via App Group.
  3. Extracts `applicationTokens` and `categoryTokens`.
  4. Sets `store.shield.applications = .all(except: applications)`.
  5. Sets `store.shield.applicationCategories = .all(except: categories)`.
  6. Sets `store.shield.webDomains = .all()`.
- **Why duplicate ShieldManager logic?** The extension process doesn't share in-memory singletons with the main app. It creates its own `ManagedSettingsStore` instance, but they both write to the same underlying system store.

**`intervalDidEnd(for activity: DeviceActivityName)`**
- Called by iOS when a registered schedule's end time is reached.
- Sequence:
  1. Calls `super.intervalDidEnd(for:)`.
  2. `store.clearAllSettings()` — removes all shields. **Apps are unblocked.**
  3. `SharedSessionStore.shared.clearSession()` — clears the session from App Group storage so the main app knows the session ended.

#### Info.plist Configuration

```xml
<key>NSExtension</key>
<dict>
    <key>NSExtensionPointIdentifier</key>
    <string>com.apple.deviceactivitymonitor</string>
    <key>NSExtensionPrincipalClass</key>
    <string>$(PRODUCT_MODULE_NAME).SleepInducerMonitor</string>
</dict>
```

- `com.apple.deviceactivitymonitor` tells iOS this extension handles DeviceActivity callbacks.
- `$(PRODUCT_MODULE_NAME).SleepInducerMonitor` resolves to `SleepInducerMonitor.SleepInducerMonitor` at build time.

---

## 12. Xcode Project Configuration

### Targets

| Target | Type | Bundle ID | Deployment |
|--------|------|-----------|------------|
| `SleepInducer` | Application | `com.sleepinducer.app` | iOS 17.0+ |
| `SleepInducerMonitor` | App Extension | `com.sleepinducer.app.monitor` | iOS 17.0+ |

### Entitlements (both targets)

```xml
<key>com.apple.security.application-groups</key>
<array>
    <string>group.com.sleepinducer.shared</string>
</array>
<key>com.apple.developer.family-controls</key>
<true/>
```

### Linked Frameworks (both targets)

- `FamilyControls.framework`
- `DeviceActivity.framework`
- `ManagedSettings.framework`

### Source File Membership

| Files | SleepInducer Target | SleepInducerMonitor Target |
|-------|:---:|:---:|
| `SleepInducer/**/*.swift` | Yes | No |
| `Shared/*.swift` | Yes | Yes |
| `SleepInducerMonitor/*.swift` | No | Yes |

### XcodeGen (project.yml)

The project is generated from `project.yml` using XcodeGen. To regenerate after structural changes:
```bash
cd /Users/spider_myan/Desktop/SleepInducer
xcodegen generate
```

---

## 13. Complete Function Reference

### Shared/AppGroupConstants

| Function/Property | Signature | Returns |
|---|---|---|
| `suiteName` | `static let suiteName: String` | `"group.com.sleepinducer.shared"` |
| `Keys.activeSession` | `static let activeSession: String` | `"activeSession"` |
| `Keys.allowedApps` | `static let allowedApps: String` | `"allowedApps"` |
| `Keys.recurringSchedule` | `static let recurringSchedule: String` | `"recurringSchedule"` |
| `Keys.defaultStrictness` | `static let defaultStrictness: String` | `"defaultStrictness"` |
| `sharedDefaults` | `static var sharedDefaults: UserDefaults` | App Group UserDefaults |

### Shared/SharedSessionStore

| Function | Signature | Returns | Side Effects |
|---|---|---|---|
| `saveSession` | `func saveSession(_ session: SleepSession)` | Void | Writes JSON to UserDefaults |
| `loadSession` | `func loadSession() -> SleepSession?` | Optional session | Reads from UserDefaults |
| `clearSession` | `func clearSession()` | Void | Removes key from UserDefaults |
| `saveAllowedApps` | `func saveAllowedApps(_ selection: FamilyActivitySelection)` | Void | Writes JSON to UserDefaults |
| `loadAllowedApps` | `func loadAllowedApps() -> FamilyActivitySelection` | Selection (never nil) | Reads from UserDefaults |
| `saveSchedule` | `func saveSchedule(_ schedule: RecurringSchedule)` | Void | Writes JSON to UserDefaults |
| `loadSchedule` | `func loadSchedule() -> RecurringSchedule?` | Optional schedule | Reads from UserDefaults |
| `clearSchedule` | `func clearSchedule()` | Void | Removes key from UserDefaults |
| `saveDefaultStrictness` | `func saveDefaultStrictness(_ mode: StrictnessMode)` | Void | Writes raw string to UserDefaults |
| `loadDefaultStrictness` | `func loadDefaultStrictness() -> StrictnessMode` | Mode (defaults to `.flexible`) | Reads from UserDefaults |

### Shared/ShieldManager

| Function | Signature | Returns | Side Effects |
|---|---|---|---|
| `activateShield` | `func activateShield(allowing selection: FamilyActivitySelection)` | Void | Writes to ManagedSettingsStore; blocks apps |
| `deactivateShield` | `func deactivateShield()` | Void | Clears ManagedSettingsStore; unblocks apps |

### Models/StrictnessMode

| Property | Signature | `.strict` | `.flexible` |
|---|---|---|---|
| `id` | `var id: String` | `"strict"` | `"flexible"` |
| `displayName` | `var displayName: String` | `"Strict"` | `"Flexible"` |
| `description` | `var description: String` | `"Cannot cancel until time is up"` | `"Cancel with a 30-second delay"` |

### Models/RecurringSchedule

| Property/Method | Signature | Description |
|---|---|---|
| `startDate` | `var startDate: Date` | Today's date at startHour:startMinute |
| `endDate` | `var endDate: Date` | Today's date at endHour:endMinute |
| `.default` | `static let default: RecurringSchedule` | 10PM-7AM, disabled, flexible |

### Models/SleepSession

| Property/Method | Signature | Description |
|---|---|---|
| `remainingTime` | `var remainingTime: TimeInterval` | Seconds until endsAt (min 0) |
| `isExpired` | `var isExpired: Bool` | True if now >= endsAt |
| `durationFormatted` | `var durationFormatted: String` | e.g., "2h", "30m", "1h 30m" |
| `manual()` | `static func manual(durationMinutes: Int, strictness: StrictnessMode) -> SleepSession` | Factory for manual sessions |

### ViewModels/AuthorizationViewModel

| Function | Signature | Returns | Side Effects |
|---|---|---|---|
| `init` | `init()` | — | Calls checkCurrentStatus() |
| `checkCurrentStatus` | `func checkCurrentStatus()` | Void | Updates isAuthorized from system |
| `requestAuthorization` | `func requestAuthorization() async` | Void | Prompts user; updates isAuthorized, isLoading, errorMessage |

### ViewModels/SessionViewModel

| Function | Signature | Returns | Side Effects |
|---|---|---|---|
| `init` | `init()` | — | Calls loadExistingSession() |
| `startManualSession` | `func startManualSession(durationMinutes: Int, strictness: StrictnessMode)` | Void | Creates session, activates shields, starts monitoring |
| `beginCancel` | `func beginCancel()` | Void | Starts 30s countdown timer; no-op if strict mode |
| `abortCancel` | `func abortCancel()` | Void | Stops countdown, resets state |
| `emergencyReset` | `func emergencyReset()` | Void | Immediately clears everything |
| `checkExpiry` | `func checkExpiry()` | Void | Ends session if expired |

### ViewModels/ScheduleViewModel

| Function | Signature | Returns | Side Effects |
|---|---|---|---|
| `init` | `init()` | — | Loads schedule from store |
| `save` | `func save()` | Void | Persists schedule, starts/stops monitoring |
| `toggleEnabled` | `func toggleEnabled()` | Void | Flips isEnabled and saves |

### ViewModels/AllowedAppsViewModel

| Function | Signature | Returns | Side Effects |
|---|---|---|---|
| `init` | `init()` | — | Loads selection from store |
| `save` | `func save()` | Void | Persists selection to store |

### Extension/SleepInducerMonitor

| Function | Signature | Returns | Side Effects |
|---|---|---|---|
| `intervalDidStart` | `override func intervalDidStart(for activity: DeviceActivityName)` | Void | Reads allowed apps, activates shields |
| `intervalDidEnd` | `override func intervalDidEnd(for activity: DeviceActivityName)` | Void | Clears shields, clears session |

---

## 14. Session Lifecycle Walkthrough

### Manual Session — Full Lifecycle (Flexible Mode)

```
1. APP LAUNCH
   └─ SleepInducerApp creates WindowGroup with ContentView
   └─ ContentView creates AuthorizationViewModel → checks auth status
   └─ ContentView creates SessionViewModel → loads any existing session from store
   └─ Auth approved + no session → shows HomeView

2. USER NAVIGATES: Home → ManualSessionView
   └─ ManualSessionView initializes with selectedDuration=60, strictness from defaults

3. USER CONFIGURES: Picks 2h duration, Flexible mode

4. USER TAPS "Start Sleep Session"
   └─ ManualSessionView calls sessionVM.startManualSession(durationMinutes: 120, strictness: .flexible)
   └─ SessionViewModel creates SleepSession(id: UUID, mode: .manual(120), strictness: .flexible,
      startedAt: now, endsAt: now+7200, isActive: true)
   └─ SessionViewModel.activateSession():
       ├─ Saves session to App Group UserDefaults
       ├─ Loads allowed apps from App Group UserDefaults
       ├─ ShieldManager writes to ManagedSettingsStore → APPS ARE NOW BLOCKED
       └─ DeviceActivityCenter registers schedule (now → now+2h, non-repeating)
   └─ sessionVM.activeSession is set → ContentView switches to ActiveSessionView

5. ACTIVE SESSION SCREEN
   └─ CountdownTimerView renders every second via TimelineView
   └─ Timer checks expiry every 5 seconds
   └─ Cancel button visible (flexible mode)

6a. SESSION EXPIRES NATURALLY
    └─ iOS fires SleepInducerMonitor.intervalDidEnd()
        ├─ Extension clears ManagedSettingsStore → APPS UNBLOCKED
        └─ Extension clears session from App Group
    └─ Next time app's checkExpiry() fires, it finds session expired
        └─ SessionViewModel.endSession() runs cleanup
        └─ activeSession = nil → ContentView switches to HomeView

6b. USER CANCELS (Flexible)
    └─ User taps "Cancel Session"
    └─ sessionVM.beginCancel() → isCancelling=true, countdown=30
    └─ UI shows "Cancelling in 30s..." + progress bar + "Keep Sleeping"
    └─ Timer ticks: 29, 28, 27...

    6b-i. USER CHANGES MIND → taps "Keep Sleeping"
          └─ sessionVM.abortCancel() → isCancelling=false, timer invalidated
          └─ Back to normal active session view

    6b-ii. COUNTDOWN REACHES 0
           └─ sessionVM.executeCancel()
               ├─ ShieldManager.deactivateShield() → APPS UNBLOCKED
               ├─ DeviceActivityCenter.stopMonitoring()
               └─ SharedSessionStore.clearSession()
           └─ activeSession = nil → ContentView switches to HomeView

7. EMERGENCY RESET (from Settings, any mode)
   └─ User taps "Emergency Reset" → confirms alert
   └─ sessionVM.emergencyReset()
       ├─ Cancel timer invalidated
       ├─ ShieldManager.deactivateShield() → APPS UNBLOCKED
       ├─ DeviceActivityCenter.stopMonitoring()
       └─ SharedSessionStore.clearSession()
   └─ activeSession = nil → ContentView switches to HomeView
```

### Recurring Schedule — Full Lifecycle

```
1. USER NAVIGATES: Home → ScheduleSetupView
   └─ ScheduleViewModel loads existing schedule (or defaults: 10PM-7AM, disabled)

2. USER ENABLES TOGGLE, adjusts times to 11PM-6:30AM, selects Strict

3. USER TAPS "Save Schedule"
   └─ ScheduleViewModel.save()
       ├─ Saves RecurringSchedule to App Group UserDefaults
       └─ DeviceActivityCenter registers "nightlySchedule" with:
           intervalStart: DateComponents(hour: 23, minute: 0)
           intervalEnd: DateComponents(hour: 6, minute: 30)
           repeats: true

4. EVERY NIGHT AT 11:00 PM
   └─ iOS fires SleepInducerMonitor.intervalDidStart(for: "nightlySchedule")
       ├─ Reads allowed apps from App Group
       └─ Writes shields to ManagedSettingsStore → APPS BLOCKED

5. EVERY MORNING AT 6:30 AM
   └─ iOS fires SleepInducerMonitor.intervalDidEnd(for: "nightlySchedule")
       ├─ Clears ManagedSettingsStore → APPS UNBLOCKED
       └─ Clears any session data from App Group

6. USER DISABLES SCHEDULE
   └─ Toggle off → ScheduleViewModel.save()
       └─ DeviceActivityCenter.stopMonitoring(["nightlySchedule"])
       └─ No more nightly callbacks
```

---

## 15. Known Constraints & Notes

### Apple Platform Requirements
- **Physical device required**: Screen Time APIs (`FamilyControls`, `ManagedSettings`, `DeviceActivity`) do not work in the iOS Simulator.
- **FamilyControls entitlement**: Must be requested from Apple Developer portal. Without it, the app will crash on `AuthorizationCenter` access.
- **iOS 16.0+**: Screen Time APIs were introduced in iOS 16. The project targets iOS 17.0 for broader API compatibility.

### Architecture Considerations
- **ManagedSettingsStore persistence**: Shield rules survive app force-quit, device restart, and extension termination. They are system-level settings managed by iOS.
- **Extension memory limits**: DeviceActivityMonitor extensions have strict memory limits (~6MB). Keep the extension code minimal — no heavy processing.
- **App Group synchronization**: UserDefaults is not transactional. In rare edge cases, a read and write from different processes could race. In practice, this is unlikely since the extension only reads and the app only writes (except `clearSession` which both call).
- **Timer accuracy**: The `Timer` in `SessionViewModel` and the `TimelineView` in `CountdownTimerView` are not perfectly precise. The DeviceActivity extension is the authoritative time source.

### What Strict Mode Actually Means
- The main app hides the cancel button, but the user could still force-quit the app.
- Since `ManagedSettingsStore` settings persist independently, force-quitting does NOT remove shields.
- The extension's `intervalDidEnd` will still fire at the scheduled time and clear the shields.
- Emergency reset in Settings is the only escape hatch (requires the app to be open).

### Data Serialization
- `FamilyActivitySelection` is natively `Codable` (Apple provides this).
- App/category tokens are opaque — they can be stored and compared but not inspected.
- All models use `JSONEncoder`/`JSONDecoder` for UserDefaults serialization.
