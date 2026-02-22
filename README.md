# Sleep Inducer 🌙

**Sleep Inducer** is a powerful iOS productivity and wellness application designed to help you reclaim your sleep by physically limiting digital distractions. Built using Apple's modern Screen Time APIs (`FamilyControls`, `ManagedSettings`, and `DeviceActivity`), it provides a robust, system-level block that helps you stay away from addictive apps and websites when it's time to rest.

---

## 🚀 Key Features

### ⏱️ Manual Sleep Sessions
Quickly start a focus block for a set duration (30m to 8h). Perfect for naps, reading time, or an earlier-than-usual bedtime.

### 📅 Nightly Recurring Schedule
Set it once and forget it. Define your "Bedtime" and "Wake Up" times, and Sleep Inducer will automatically engage the shields every single night.

### 🛡️ Strict vs. Flexible Modes
- **Strict Mode:** No escape. Once the session starts, the "Cancel" button is removed. You must wait for the timer to expire.
- **Flexible Mode:** Includes a mandatory **30-second delay** for cancellations, forcing you to think twice before breaking your sleep goal.

### ✅ Allowed Apps Whitelist
Choose exactly which apps stay accessible. Keep your Phone, Messages, or Meditation apps active while silencing everything else.

### ❤️ HealthKit Insights
See the real impact on your sleep. Sleep Inducer connects to Apple Health to show:
- **Sleep Improvement:** A comparative analysis of how much more deep sleep you get on nights you use the app.
- **Wind-down Reminders:** Real-time heart rate monitoring that suggests starting a session if your stress levels are high before bed.

### 🌑 Modern Aesthetic
A beautiful, "Always-Dark" UI featuring:
- Interactive countdown rings.
- Glowing moon iconography.
- Fluid, animated transitions.
- Intuitive card-based navigation.

---

## 🛠️ Technical Architecture

Sleep Inducer is built with a robust **MVVM** (Model-View-ViewModel) architecture and leverages a multi-process strategy to ensure blocks are enforced even if the app is closed.

### 1. Main App Target (`SleepInducer`)
Handles the user interface, session configuration, and authorization. It communicates with the system to schedule "Device Activity" windows.

### 2. Monitor Extension Target (`SleepInducerMonitor`)
A system-managed process that runs in the background. It is triggered by iOS at the start and end of every scheduled interval to apply or remove shields, ensuring high reliability even if the main app is force-quit.

### 3. Shared Layer
A synchronized data layer using **App Groups** and **UserDefaults** to share session state, allowed app selections, and schedule configurations between the app and the extension.

---

## 🧬 Frameworks & APIs

| Framework | Purpose |
|-----------|---------|
| **FamilyControls** | Securely requests Screen Time permissions and provides the native app-picker UI. |
| **ManagedSettings** | Enforces the actual blocks on apps, categories, and web domains at the system level. |
| **DeviceActivity** | Schedules the background callbacks that trigger the start and end of sleep sessions. |
| **SwiftUI** | Powers the modern, reactive user interface and theme system. |

---

## 📦 Requirements & Setup

- **iOS 17.0+**
- **Physical Device Required:** Screen Time APIs do not function in the iOS Simulator.
- **Entitlements:** Requires the `FamilyControls` and `App Groups` entitlements from the Apple Developer Portal.

### Development Setup
1. Clone the repository:
   ```bash
   git clone git@github.com:GKR5413/Sleep_Inducer.git
   ```
2. Generate the Xcode project using **XcodeGen**:
   ```bash
   xcodegen generate
   ```
3. Open `SleepInducer.xcodeproj` and sign the targets with your development team.
4. Run the app on a physical iPhone.

---

## 📝 Usage Guide

1. **Grant Access:** Upon first launch, tap "Grant Access" to authorize Screen Time permissions.
2. **Configure Allowed Apps:** Go to "Allowed Apps" to select which tools (like Music or Phone) should remain unblocked.
3. **Start a Session:** Use the "Start Now" card for a manual block or "Nightly Schedule" to automate your sleep hygiene.
4. **Emergency Reset:** If you are ever stuck, an Emergency Reset is available in the Settings menu.

---

Developed with ❤️ to help you sleep better.
