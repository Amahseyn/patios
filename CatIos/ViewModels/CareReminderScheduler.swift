import Foundation
import UserNotifications

@MainActor
final class CareReminderScheduler {
    static let shared = CareReminderScheduler()

    private let prefix = "care-task-"

    func reschedule(tasks: [CustomCareTask]) {
        Task { await rescheduleNow(tasks: tasks) }
    }

    func scheduleFollowingOccurrence(identifier: String) async {
        guard identifier.hasPrefix(prefix) else { return }
        await rescheduleNow(tasks: CareTaskStore.shared.tasks)
    }

    func rescheduleNow(tasks: [CustomCareTask]) async {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        let pending = await center.pendingNotificationRequests()
        let existing = pending.map(\.identifier).filter { $0.hasPrefix(prefix) }
        center.removePendingNotificationRequests(withIdentifiers: existing)

        let master = NotificationPreferences.isOn(NotificationPreferences.masterKey)
        let tasksOn = NotificationPreferences.isOn(NotificationPreferences.tasksKey)
        guard master, tasksOn, settings.authorizationStatus == .authorized else { return }

        let now = Date()
        for task in tasks where task.alarmEnabled {
            guard let fire = nextFireDate(for: task, after: now) else { continue }
            let content = UNMutableNotificationContent()
            content.title = "Care reminder"
            content.body = "\(task.emojiIcon) \(task.title)"
            content.sound = .default
            let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: fire)
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            let request = UNNotificationRequest(
                identifier: prefix + task.id.uuidString,
                content: content,
                trigger: trigger
            )
            try? await center.add(request)
        }
    }

    private func nextFireDate(for task: CustomCareTask, after now: Date) -> Date? {
        let calendar = Calendar.current
        let minutes = CareSchedule.minutes(from: task.timeText)
        let hour = minutes / 60
        let minute = minutes % 60
        for offset in 0...14 {
            guard let day = calendar.date(byAdding: .day, value: offset, to: calendar.startOfDay(for: now)) else { continue }
            guard CareSchedule.occurs(task, on: day, calendar: calendar) else { continue }
            var components = calendar.dateComponents([.year, .month, .day], from: day)
            components.hour = hour
            components.minute = minute
            guard let fire = calendar.date(from: components), fire > now.addingTimeInterval(30) else { continue }
            return fire
        }
        return nil
    }
}

final class CareNotificationBridge: NSObject, UNUserNotificationCenterDelegate {
    static let shared = CareNotificationBridge()

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        await CareReminderScheduler.shared.scheduleFollowingOccurrence(identifier: notification.request.identifier)
        return [.banner, .sound, .list]
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        await CareReminderScheduler.shared.scheduleFollowingOccurrence(identifier: response.notification.request.identifier)
    }
}
