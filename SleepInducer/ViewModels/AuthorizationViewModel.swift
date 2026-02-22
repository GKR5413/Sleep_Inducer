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
            isAuthorized = true
        } catch {
            errorMessage = "Screen Time authorization is required. Please enable it in Settings."
            isAuthorized = false
        }

        isLoading = false
    }
}
