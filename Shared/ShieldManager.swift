import ManagedSettings
import FamilyControls

final class ShieldManager: @unchecked Sendable {
    static let shared = ShieldManager()
    
    // A single store is more efficient than creating multiple instances
    private let store = ManagedSettingsStore()
    
    private init() {}
    
    /// Blocks all applications except the ones in the provided selection.
    func activateShield(allowing selection: FamilyActivitySelection) {
        // Clear previous settings to ensure a clean state
        store.clearAllSettings()
        
        // Shield specific individual applications
        store.shield.applications = selection.applicationTokens.isEmpty ? nil : selection.applicationTokens
        
        // Shield specific categories
        store.shield.applicationCategories = selection.categoryTokens.isEmpty ? nil : .specific(selection.categoryTokens)
        
        // Shield all web domains
        store.shield.webDomains = selection.webDomainTokens.isEmpty ? nil : selection.webDomainTokens
    }

    /// Removes all shields and clears managed settings.
    func deactivateShield() {
        store.clearAllSettings()
    }
}
