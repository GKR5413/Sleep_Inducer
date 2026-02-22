import SwiftUI
import UIKit
import UserNotifications

struct ActiveSessionView: View {
    @ObservedObject var sessionVM: SessionViewModel
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            if let session = sessionVM.activeSession {
                // Moon icon
                Image(systemName: "moon.zzz.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(SleepTheme.warmGold)

                Text("Sleep Mode Active")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(SleepTheme.softWhite)

                // Countdown ring
                CountdownTimerView(
                    endsAt: session.endsAt,
                    totalDuration: session.endsAt.timeIntervalSince(session.startedAt)
                )

                // Session info
                VStack(spacing: 8) {
                    Label(session.durationFormatted, systemImage: "clock")
                    Label(session.strictness.displayName + " Mode", systemImage: session.strictness == .strict ? "lock.fill" : "lock.open.fill")
                }
                .font(.subheadline)
                .foregroundStyle(SleepTheme.lavender.opacity(0.7))

                #if targetEnvironment(simulator)
                Text("Simulation Mode: Shields Inactive")
                    .font(.caption)
                    .foregroundStyle(SleepTheme.dangerRed)
                    .padding(.top, 4)
                #endif

                // Guided Access Hint
                if !UIAccessibility.isGuidedAccessEnabled {
                    Text("Tip: Triple-click side button for Guided Access")
                        .font(.caption2)
                        .foregroundStyle(SleepTheme.lavender.opacity(0.5))
                        .padding(.top, 4)
                }

                Spacer()

                // Cancel section (flexible mode only)
                if session.strictness == .flexible {
                    if sessionVM.isCancelling {
                        VStack(spacing: 12) {
                            Text("Cancelling in \(sessionVM.cancelCountdown)s...")
                                .font(.headline)
                                .foregroundStyle(SleepTheme.dangerRed)

                            ProgressView(value: Double(30 - sessionVM.cancelCountdown), total: 30)
                                .tint(SleepTheme.dangerRed)
                                .padding(.horizontal, 40)

                            SleepButton("Keep Sleeping", icon: "moon.fill", style: .secondary) {
                                sessionVM.abortCancel()
                            }
                            .padding(.horizontal, 40)
                        }
                    } else {
                        SleepButton("Cancel Session", icon: "xmark", style: .danger) {
                            sessionVM.beginCancel()
                        }
                        .padding(.horizontal, 40)

                        Text("30-second delay before cancellation")
                            .font(.caption)
                            .foregroundStyle(SleepTheme.lavender.opacity(0.4))
                    }
                } else {
                    Text("Strict mode - session cannot be cancelled")
                        .font(.caption)
                        .foregroundStyle(SleepTheme.lavender.opacity(0.4))
                }
            }

            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(SleepTheme.backgroundGradient.ignoresSafeArea())
        .onReceive(Timer.publish(every: 5, on: .main, in: .common).autoconnect()) { _ in
            sessionVM.checkExpiry()
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .background {
                scheduleReturnNotification()
            }
        }
        .task {
             _ = try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])
        }
    }

    private func scheduleReturnNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Sleep Session Active"
        content.body = "Return to Sleep Inducer to maintain your session."
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: "returnToApp", content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request)
    }
}
