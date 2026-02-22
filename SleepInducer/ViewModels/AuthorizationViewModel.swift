import SwiftUI
import FamilyControls

@MainActor
final class AuthorizationViewModel: ObservableObject {
    @Published var isAuthorized = false
    @Published var isLoading = false
    @Published var errorMessage: String?

    init() {
        checkCurrentStatus()
    }

    func checkCurrentStatus() {
        isAuthorized = AuthorizationCenter.shared.authorizationStatus == .approved
    }

    func requestAuthorization() async {
        isLoading = true
        errorMessage = nil

        do {
            try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
            isAuthorized = AuthorizationCenter.shared.authorizationStatus == .approved
            if !isAuthorized {
                errorMessage = "Authorization was not approved. Please enable Screen Time in System Settings."
            }
        } catch {
            #if targetEnvironment(simulator)
            errorMessage = "Screen Time APIs are not available in the Simulator. Please use a physical device."
            #else
            errorMessage = "Authorization failed: \(error.localizedDescription). Please ensure you have signed in to iCloud."
            #endif
            isAuthorized = false
        }

        isLoading = false
    }
}
