import DeviceActivity
import ManagedSettings
import FamilyControls

class SleepInducerMonitor: DeviceActivityMonitor {

    private let store = ManagedSettingsStore()

    override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)

        // Load allowed apps from shared store and activate shields
        let selection = SharedSessionStore.shared.loadAllowedApps()
        let applications = selection.applicationTokens

        store.shield.applicationCategories = .all(except: applications)
        store.shield.webDomainCategories = .all()
    }

    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)

        // Remove all shields and clear session
        store.clearAllSettings()
        SharedSessionStore.shared.clearSession()
    }
}
