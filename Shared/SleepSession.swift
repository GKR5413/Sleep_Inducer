import Foundation

struct SleepSession: Codable, Identifiable, Equatable {
    let id: UUID
    let mode: ScheduleMode
    let strictness: StrictnessMode
    let startedAt: Date
    let endsAt: Date
    var isActive: Bool

    var remainingTime: TimeInterval {
        max(0, endsAt.timeIntervalSince(.now))
    }

    var isExpired: Bool {
        Date.now >= endsAt
    }

    var durationFormatted: String {
        let total = Int(endsAt.timeIntervalSince(startedAt))
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        if hours > 0 {
            return minutes > 0 ? "\(hours)h \(minutes)m" : "\(hours)h"
        }
        return "\(minutes)m"
    }

    static func manual(durationMinutes: Int, strictness: StrictnessMode) -> SleepSession {
        let now = Date.now
        return SleepSession(
            id: UUID(),
            mode: .manual(durationMinutes: durationMinutes),
            strictness: strictness,
            startedAt: now,
            endsAt: now.addingTimeInterval(TimeInterval(durationMinutes * 60)),
            isActive: true
        )
    }
}
