import Foundation
import FamilyControls

protocol AuthorizationProvider: Sendable {
    var status: AuthorizationStatus { get }
    func requestAuthorization() async throws
}

struct RealAuthorizationProvider: AuthorizationProvider {
    var status: AuthorizationStatus {
        AuthorizationCenter.shared.authorizationStatus
    }
    
    func requestAuthorization() async throws {
        try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
    }
}

#if DEBUG
struct MockAuthorizationProvider: AuthorizationProvider {
    // In simulator, we simulate being approved for UI testing
    var status: AuthorizationStatus {
        #if targetEnvironment(simulator)
        return .approved
        #else
        return AuthorizationCenter.shared.authorizationStatus
        #endif
    }
    
    func requestAuthorization() async throws {
        // Simulate a successful network/system delay
        try await Task.sleep(nanoseconds: 500_000_000)
    }
}
#endif
