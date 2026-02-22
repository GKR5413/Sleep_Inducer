import Foundation

enum AppGroupConstants {
    static let suiteName = "group.com.sleepinducer.shared"

    enum Keys {
        static let activeSession = "activeSession"
        static let allowedApps = "allowedApps"
        static let recurringSchedule = "recurringSchedule"
        static let defaultStrictness = "defaultStrictness"
    }

    static var sharedDefaults: UserDefaults {
        UserDefaults(suiteName: suiteName) ?? .standard
    }
}
