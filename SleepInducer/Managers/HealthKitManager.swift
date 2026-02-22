import Foundation
import HealthKit

@MainActor
class HealthKitManager: ObservableObject {
    static let shared = HealthKitManager()
    
    private let provider: any HealthKitProvider
    
    @Published var isAuthorized = false
    @Published var sleepData: [SleepEntry] = []
    @Published var latestHeartRate: Double = 0
    @Published var sleepImprovementMinutes: Int = 0
    
    struct SleepEntry: Identifiable {
        let id = UUID()
        let date: Date
        let duration: TimeInterval
        let type: String // "Deep", "REM", "Core", "Awake"
    }
    
    init(provider: any HealthKitProvider = defaultProvider) {
        self.provider = provider
        checkAuthorization()
    }
    
    private static var defaultProvider: any HealthKitProvider {
        #if targetEnvironment(simulator)
        return MockHealthKitProvider()
        #else
        return RealHealthKitProvider()
        #endif
    }
    
    func checkAuthorization() {
        guard provider.isHealthDataAvailable() else {
            self.isAuthorized = false
            return
        }
        
        #if targetEnvironment(simulator)
        self.isAuthorized = true
        self.fetchAllData()
        #else
        // On real devices, check actual status via query or status check
        // For simplicity in this demo, we'll request if not unnecessary
        #endif
    }
    
    func requestAuthorization() {
        guard provider.isHealthDataAvailable() else {
            self.isAuthorized = false
            return
        }

        let typesToRead: Set: Set<HKObjectType> = [
            HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!,
            HKObjectType.quantityType(forIdentifier: .heartRate)!
        ]
        
        Task {
            do {
                let success = try await provider.requestAuthorization(toShare: [], read: typesToRead)
                self.isAuthorized = success
                if success {
                    self.fetchAllData()
                }
            } catch {
                print("HealthKit Auth Failed: \(error)")
            }
        }
    }
    
    func fetchAllData() {
        #if targetEnvironment(simulator)
        // Simulated data for development
        self.latestHeartRate = 72
        self.sleepImprovementMinutes = 45
        #else
        fetchSleepData()
        fetchLatestHeartRate()
        #endif
    }
    
    func fetchSleepData() {
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else { return }
        
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        let startDate = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: Date(), options: .strictStartDate)
        
        let query = HKSampleQuery(sampleType: sleepType, predicate: predicate, limit: 100, sortDescriptors: [sortDescriptor]) { (query, samples, error) in
            guard let samples = samples as? [HKCategorySample] else { return }
            
            var entries: [SleepEntry] = []
            
            for sample in samples {
                let duration = sample.endDate.timeIntervalSince(sample.startDate)
                let typeStr: String
                
                if #available(iOS 16.0, *) {
                    switch sample.value {
                    case HKCategoryValueSleepAnalysis.asleepDeep.rawValue: typeStr = "Deep"
                    case HKCategoryValueSleepAnalysis.asleepREM.rawValue: typeStr = "REM"
                    case HKCategoryValueSleepAnalysis.asleepCore.rawValue: typeStr = "Core"
                    default: typeStr = "Awake"
                    }
                } else {
                    typeStr = sample.value == HKCategoryValueSleepAnalysis.asleep.rawValue ? "Asleep" : "Awake"
                }
                
                entries.append(SleepEntry(date: sample.startDate, duration: duration, type: typeStr))
            }
            
            DispatchQueue.main.async {
                self.sleepData = entries
                self.sleepImprovementMinutes = 45 
            }
        }
        
        provider.execute(query)
    }
    
    func fetchLatestHeartRate() {
        guard let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate) else { return }
        
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        let query = HKSampleQuery(sampleType: heartRateType, predicate: nil, limit: 1, sortDescriptors: [sortDescriptor]) { (query, samples, error) in
            guard let sample = samples?.first as? HKQuantitySample else { return }
            
            let hrUnit = HKUnit(from: "count/min")
            let heartRate = sample.quantity.doubleValue(for: hrUnit)
            
            DispatchQueue.main.async {
                self.latestHeartRate = heartRate
            }
        }
        
        provider.execute(query)
    }
}
