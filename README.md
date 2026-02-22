# Sleep Inducer

**Sleep Inducer** is a sophisticated iOS productivity and wellness application designed to improve sleep quality by physically limiting digital distractions. Built using Apple's modern Screen Time APIs (`FamilyControls`, `ManagedSettings`, and `DeviceActivity`), it provides a robust, system-level block that helps users stay away from addictive apps and websites during designated rest periods.

---

## Key Features

### Manual Sleep Sessions
Quickly initiate a focus block for a specific duration (30 minutes to 8 hours). Suitable for naps, focused reading, or an earlier-than-usual bedtime.

### Nightly Recurring Schedule
Automated scheduling for consistent sleep hygiene. Define "Bedtime" and "Wake Up" times, and Sleep Inducer will automatically engage the system shields every night.

### Strict vs. Flexible Modes
- **Strict Mode:** Ensures total commitment. Once the session starts, the cancellation option is disabled until the timer expires.
- **Flexible Mode:** Includes a mandatory 30-second delay for cancellations to discourage impulsive use.

### Allowed Apps Whitelist
Granular control over accessible content. Maintain access to essential tools like Phone, Messages, or Meditation apps while blocking all other distractions.

### HealthKit Insights
Quantifiable impact on sleep quality. Sleep Inducer integrates with Apple Health to provide:
- **Sleep Improvement:** Comparative analysis of deep sleep duration on nights when the app is active.
- **Wind-down Reminders:** Heart rate monitoring that suggests starting a session if elevated stress levels are detected before bedtime.

### Modern Architecture
A professional, "Always-Dark" user interface featuring:
- High-precision countdown timers.
- Integrated HealthKit dashboards.
- Fluid, system-native transitions.
- Scalable card-based navigation.

---

## Technical Architecture

Sleep Inducer is built with a robust **MVVM** (Model-View-ViewModel) architecture and utilizes a multi-process strategy to ensure blocks are enforced regardless of the app's state.

### 1. Main App Target (SleepInducer)
Responsible for the user interface, session configuration, and authorization. It manages the scheduling of Device Activity windows with the system.

### 2. Monitor Extension Target (SleepInducerMonitor)
A system-managed process that runs independently of the main app. It is triggered by iOS at the start and end of every scheduled interval to apply or remove shields, ensuring high reliability.

### 3. Shared Layer
A synchronized data layer using **App Groups** and **UserDefaults** to share session state, allowed app selections, and schedule configurations between the primary app and the background extension.

---

## Frameworks & APIs

| Framework | Purpose |
|-----------|---------|
| **FamilyControls** | Manages Screen Time permissions and provides the native application selection interface. |
| **ManagedSettings** | Enforces system-level blocks on applications, categories, and web domains. |
| **DeviceActivity** | Handles the background scheduling for the start and end of sleep sessions. |
| **HealthKit** | Integrates biometric and sleep data for performance tracking. |
| **SwiftUI** | Powers the reactive user interface and theme system. |

---

## Requirements & Setup

- **iOS 17.0+**
- **Physical Device Required:** Screen Time APIs are not functional within the iOS Simulator.
- **Entitlements:** Requires `FamilyControls` and `App Groups` entitlements.

### Development Setup
1. Clone the repository:
   ```bash
   git clone git@github.com:GKR5413/Sleep_Inducer.git
   ```
2. Generate the Xcode project using **XcodeGen**:
   ```bash
   xcodegen generate
   ```
3. Open `SleepInducer.xcodeproj` and configure the targets with a valid development team.
4. Deploy the application to a physical iPhone.

---

## Usage Guide

1. **Authorization:** Upon initial launch, authorize Screen Time permissions.
2. **Configuration:** Select essential applications in the "Allowed Apps" section.
3. **Session Activation:** Use the "Start Now" feature for manual blocks or the "Nightly Schedule" for automated enforcement.
4. **Emergency Reset:** An emergency override is available within the Settings menu if required.

---

Developed to support healthier digital habits and improved rest.
