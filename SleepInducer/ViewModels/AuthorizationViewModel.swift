import SwiftUI
import FamilyControls

@MainActor
final class AuthorizationViewModel: ObservableObject {
    @Published var isAuthorized = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let provider: any AuthorizationProvider

    init(provider: any AuthorizationProvider = defaultProvider) {
        self.provider = provider
        checkCurrentStatus()
    }
    
    private static var defaultProvider: any AuthorizationProvider {
        #if targetEnvironment(simulator)
        return MockAuthorizationProvider()
        #else
        return RealAuthorizationProvider()
        #endif
    }

    func checkCurrentStatus() {
        isAuthorized = provider.status == .approved
    }

    func requestAuthorization() async {
        isLoading = true
        errorMessage = nil

        do {
            try await provider.requestAuthorization()
            isAuthorized = provider.status == .approved
            if !isAuthorized {
                errorMessage = "Authorization was not approved. Please enable Screen Time in System Settings."
            }
        } catch {
            errorMessage = "Authorization failed: \(error.localizedDescription)"
            isAuthorized = false
        }

        isLoading = false
    }
}
