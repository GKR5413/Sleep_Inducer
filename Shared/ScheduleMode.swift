import Foundation

enum ScheduleMode: Codable, Equatable {
    case manual(durationMinutes: Int)
    case recurring(startHour: Int, startMinute: Int, endHour: Int, endMinute: Int)
}

struct RecurringSchedule: Codable, Equatable {
    var isEnabled: Bool
    var startHour: Int
    var startMinute: Int
    var endHour: Int
    var endMinute: Int
    var strictness: StrictnessMode

    static let `default` = RecurringSchedule(
        isEnabled: false,
        startHour: 22,
        startMinute: 0,
        endHour: 7,
        endMinute: 0,
        strictness: .flexible
    )

    var startDate: Date {
        Calendar.current.date(from: DateComponents(hour: startHour, minute: startMinute)) ?? .now
    }

    var endDate: Date {
        Calendar.current.date(from: DateComponents(hour: endHour, minute: endMinute)) ?? .now
    }
}
