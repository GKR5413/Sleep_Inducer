import ManagedSettings
import FamilyControls

final class ShieldManager: @unchecked Sendable {
    static let shared = ShieldManager()

    private let store = ManagedSettingsStore()

    private init() {}

    /// Blocks all applications except the ones in the provided selection.
    func activateShield(allowing selection: FamilyActivitySelection) {
        let applications = selection.applicationTokens

        // Shield all app categories, exempting specific allowed apps
        store.shield.applicationCategories = .all(except: applications)

        // Shield all web domain categories
        store.shield.webDomainCategories = .all()
    }

    /// Removes all shields and clears managed settings.
    func deactivateShield() {
        store.clearAllSettings()
    }
}
