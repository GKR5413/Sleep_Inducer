import ManagedSettings
import FamilyControls

final class ShieldManager: @unchecked Sendable {
    static let shared = ShieldManager()
    
    // A single store is more efficient than creating multiple instances
    private let store = ManagedSettingsStore()
    
    private init() {}
    
    /// Blocks all applications except the ones in the provided selection.
    func activateShield(allowing selection: FamilyActivitySelection) {
        let applications = selection.applicationTokens
        let categories = selection.categoryTokens
        
        // Block everything except specific allowed apps/categories
        // This is the most battery-efficient way to handle system-level blocking
        store.shield.applications = .all(except: applications)
        store.shield.applicationCategories = .all(except: categories)
        store.shield.webDomains = .all()
    }

    /// Removes all shields and clears managed settings.
    func deactivateShield() {
        store.clearAllSettings()
    }
}
