import DeviceActivity
import ManagedSettings
import FamilyControls

class SleepInducerMonitor: DeviceActivityMonitor {

    private let store = ManagedSettingsStore()

    override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)

        // Load allowed apps from shared store and activate shields
        let selection = SharedSessionStore.shared.loadAllowedApps()

        // Shield specific individual applications
        store.shield.applications = selection.applicationTokens.isEmpty ? nil : selection.applicationTokens
        
        // Shield specific categories
        store.shield.applicationCategories = selection.categoryTokens.isEmpty ? nil : .specific(selection.categoryTokens)
        
        // Shield specific web domains
        store.shield.webDomains = selection.webDomainTokens.isEmpty ? nil : selection.webDomainTokens
    }

    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)

        // Remove all shields and clear session
        store.clearAllSettings()
        SharedSessionStore.shared.clearSession()
    }
}
