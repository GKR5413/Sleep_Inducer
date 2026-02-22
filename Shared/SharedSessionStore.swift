import Foundation
import FamilyControls

final class SharedSessionStore: @unchecked Sendable {
    static let shared = SharedSessionStore()

    private let defaults = AppGroupConstants.sharedDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    private init() {}

    // MARK: - Active Session

    func saveSession(_ session: SleepSession) {
        if let data = try? encoder.encode(session) {
            defaults.set(data, forKey: AppGroupConstants.Keys.activeSession)
        }
    }

    func loadSession() -> SleepSession? {
        guard let data = defaults.data(forKey: AppGroupConstants.Keys.activeSession) else {
            return nil
        }
        return try? decoder.decode(SleepSession.self, from: data)
    }

    func clearSession() {
        defaults.removeObject(forKey: AppGroupConstants.Keys.activeSession)
    }

    // MARK: - Allowed Apps

    func saveAllowedApps(_ selection: FamilyActivitySelection) {
        if let data = try? encoder.encode(selection) {
            defaults.set(data, forKey: AppGroupConstants.Keys.allowedApps)
        }
    }

    func loadAllowedApps() -> FamilyActivitySelection {
        guard let data = defaults.data(forKey: AppGroupConstants.Keys.allowedApps) else {
            return FamilyActivitySelection()
        }
        return (try? decoder.decode(FamilyActivitySelection.self, from: data)) ?? FamilyActivitySelection()
    }

    // MARK: - Recurring Schedule

    func saveSchedule(_ schedule: RecurringSchedule) {
        if let data = try? encoder.encode(schedule) {
            defaults.set(data, forKey: AppGroupConstants.Keys.recurringSchedule)
        }
    }

    func loadSchedule() -> RecurringSchedule? {
        guard let data = defaults.data(forKey: AppGroupConstants.Keys.recurringSchedule) else {
            return nil
        }
        return try? decoder.decode(RecurringSchedule.self, from: data)
    }

    func clearSchedule() {
        defaults.removeObject(forKey: AppGroupConstants.Keys.recurringSchedule)
    }

    // MARK: - Default Strictness

    func saveDefaultStrictness(_ mode: StrictnessMode) {
        defaults.set(mode.rawValue, forKey: AppGroupConstants.Keys.defaultStrictness)
    }

    func loadDefaultStrictness() -> StrictnessMode {
        guard let raw = defaults.string(forKey: AppGroupConstants.Keys.defaultStrictness) else {
            return .flexible
        }
        return StrictnessMode(rawValue: raw) ?? .flexible
    }
}
