import SwiftUI
import DeviceActivity
import FamilyControls

@MainActor
final class SessionViewModel: ObservableObject {
    @Published var activeSession: SleepSession?
    @Published var isCancelling = false
    @Published var cancelCountdown: Int = 30

    private let store = SharedSessionStore.shared
    private let shieldManager = ShieldManager.shared
    private let activityCenter = DeviceActivityCenter()
    private var cancelTimer: Timer?

    init() {
        loadExistingSession()
    }

    var hasActiveSession: Bool {
        activeSession?.isActive == true
    }

    // MARK: - Start Session

    func startManualSession(durationMinutes: Int, strictness: StrictnessMode) {
        let session = SleepSession.manual(durationMinutes: durationMinutes, strictness: strictness)
        activateSession(session)
    }

    // MARK: - Cancel Session (Flexible Mode)

    func beginCancel() {
        guard activeSession?.strictness == .flexible else { return }
        isCancelling = true
        cancelCountdown = 30

        cancelTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self else { return }
            MainActor.assumeIsolated {
                self.cancelCountdown -= 1
                if self.cancelCountdown <= 0 {
                    self.cancelTimer?.invalidate()
                    self.cancelTimer = nil
                    self.executeCancel()
                }
            }
        }
    }

    func abortCancel() {
        isCancelling = false
        cancelCountdown = 30
        cancelTimer?.invalidate()
        cancelTimer = nil
    }

    // MARK: - Emergency Reset

    func emergencyReset() {
        cancelTimer?.invalidate()
        cancelTimer = nil
        shieldManager.deactivateShield()
        stopMonitoring()
        store.clearSession()
        activeSession = nil
        isCancelling = false
    }

    // MARK: - Check Expiry

    func checkExpiry() {
        guard let session = activeSession, session.isExpired else { return }
        endSession()
    }

    // MARK: - Private

    private func activateSession(_ session: SleepSession) {
        store.saveSession(session)
        activeSession = session

        let allowedApps = store.loadAllowedApps()
        shieldManager.activateShield(allowing: allowedApps)

        startMonitoring(until: session.endsAt)
    }

    private func executeCancel() {
        isCancelling = false
        cancelTimer = nil
        endSession()
    }

    private func endSession() {
        shieldManager.deactivateShield()
        stopMonitoring()
        store.clearSession()
        activeSession = nil
    }

    private func loadExistingSession() {
        guard let session = store.loadSession() else { return }
        if session.isExpired {
            endSession()
        } else {
            activeSession = session
        }
    }

    private func startMonitoring(until endDate: Date) {
        let activityName = DeviceActivityName("sleepSession")
        let schedule = DeviceActivitySchedule(
            intervalStart: Calendar.current.dateComponents([.hour, .minute, .second], from: .now),
            intervalEnd: Calendar.current.dateComponents([.hour, .minute, .second], from: endDate),
            repeats: false
        )

        do {
            try activityCenter.startMonitoring(activityName, during: schedule)
        } catch {
            print("Failed to start monitoring: \(error)")
        }
    }

    private func stopMonitoring() {
        activityCenter.stopMonitoring([DeviceActivityName("sleepSession")])
    }
}
