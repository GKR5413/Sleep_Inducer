import Foundation
import HealthKit

protocol HealthKitProvider: Sendable {
    func isHealthDataAvailable() -> Bool
    func requestAuthorization(toShare: Set<HKSampleType>, read: Set<HKObjectType>) async throws -> Bool
    func execute(_ query: HKQuery)
}

struct RealHealthKitProvider: HealthKitProvider {
    private let healthStore = HKHealthStore()
    
    func isHealthDataAvailable() -> Bool {
        HKHealthStore.isHealthDataAvailable()
    }
    
    func requestAuthorization(toShare: Set<HKSampleType>, read: Set<HKObjectType>) async throws -> Bool {
        try await healthStore.requestAuthorization(toShare: toShare, read: read)
        return true
    }
    
    func execute(_ query: HKQuery) {
        healthStore.execute(query)
    }
}

#if DEBUG
struct MockHealthKitProvider: HealthKitProvider {
    func isHealthDataAvailable() -> Bool {
        return true
    }
    
    func requestAuthorization(toShare: Set<HKSampleType>, read: Set<HKObjectType>) async throws -> Bool {
        try await Task.sleep(nanoseconds: 500_000_000)
        return true
    }
    
    func execute(_ query: HKQuery) {
        // In mock mode, we manually trigger the completion handlers of queries
        // with simulated data if needed, or rely on the Manager's fallback logic.
    }
}
#endif
