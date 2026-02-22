import SwiftUI
import FamilyControls

@MainActor
final class AllowedAppsViewModel: ObservableObject {
    @Published var activitySelection: FamilyActivitySelection

    private let store = SharedSessionStore.shared

    init() {
        activitySelection = store.loadAllowedApps()
    }

    func save() {
        store.saveAllowedApps(activitySelection)
    }
}
