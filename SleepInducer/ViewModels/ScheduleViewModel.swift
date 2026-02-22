import SwiftUI
import DeviceActivity

@MainActor
final class ScheduleViewModel: ObservableObject {
    @Published var schedule: RecurringSchedule

    private let store = SharedSessionStore.shared
    private let activityCenter = DeviceActivityCenter()

    init() {
        schedule = store.loadSchedule() ?? .default
    }

    var startTime: Date {
        get { schedule.startDate }
        set {
            let components = Calendar.current.dateComponents([.hour, .minute], from: newValue)
            schedule.startHour = components.hour ?? 22
            schedule.startMinute = components.minute ?? 0
        }
    }

    var endTime: Date {
        get { schedule.endDate }
        set {
            let components = Calendar.current.dateComponents([.hour, .minute], from: newValue)
            schedule.endHour = components.hour ?? 7
            schedule.endMinute = components.minute ?? 0
        }
    }

    func save() {
        store.saveSchedule(schedule)

        if schedule.isEnabled {
            startScheduleMonitoring()
        } else {
            stopScheduleMonitoring()
        }
    }

    func toggleEnabled() {
        schedule.isEnabled.toggle()
        save()
    }

    // MARK: - Private

    private func startScheduleMonitoring() {
        let activityName = DeviceActivityName("nightlySchedule")
        let activitySchedule = DeviceActivitySchedule(
            intervalStart: DateComponents(hour: schedule.startHour, minute: schedule.startMinute),
            intervalEnd: DateComponents(hour: schedule.endHour, minute: schedule.endMinute),
            repeats: true
        )

        do {
            try activityCenter.startMonitoring(activityName, during: activitySchedule)
        } catch {
            print("Failed to start schedule monitoring: \(error)")
        }
    }

    private func stopScheduleMonitoring() {
        activityCenter.stopMonitoring([DeviceActivityName("nightlySchedule")])
    }
}
