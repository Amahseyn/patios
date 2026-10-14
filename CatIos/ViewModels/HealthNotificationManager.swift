import Foundation
import UserNotifications
import SwiftUI
import Combine

@MainActor
class HealthNotificationManager: ObservableObject {
    static let shared = HealthNotificationManager()

    @Published var authorizationStatus: UNAuthorizationStatus = .notDetermined

    private init() {
        checkAuthorizationStatus()
    }

    func checkAuthorizationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
            guard let self else { return }
            DispatchQueue.main.async {
                self.authorizationStatus = settings.authorizationStatus
            }
        }
    }

    func requestAuthorization() async -> Bool {
        let granted = (try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound])) ?? false
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        authorizationStatus = settings.authorizationStatus
        return granted
    }

    func scheduleReminders(for record: HealthRecord) {
        guard NotificationPreferences.isOn(NotificationPreferences.masterKey) else { return }
        guard NotificationPreferences.isOn(NotificationPreferences.healthKey) else { return }
        guard let nextDueDate = record.nextDueDate else { return }
        guard record.isReminderSet == true else { return }
        guard authorizationStatus == .authorized else { return }

        let center = UNUserNotificationCenter.current()
        let recordTitle = record.title.isEmpty ? record.recordType.rawValue : record.title

        if let beforeDate = Calendar.current.date(byAdding: .day, value: -1, to: nextDueDate),
           beforeDate > Date() {
            let content = UNMutableNotificationContent()
            content.title = "🐾 Health Reminder"
            content.body = "\(recordTitle) is due tomorrow."
            content.sound = .default

            let trigger = UNCalendarNotificationTrigger(
                dateMatching: dateComponents(for: beforeDate, hour: 9, minute: 0),
                repeats: false
            )
            let request = UNNotificationRequest(
                identifier: "\(record.id.uuidString)-dayBefore",
                content: content,
                trigger: trigger
            )
            center.add(request)
        }

        if nextDueDate > Date() {
            let content = UNMutableNotificationContent()
            content.title = "🐾 Health Reminder"
            content.body = "\(recordTitle) is due today."
            content.sound = .default

            let trigger = UNCalendarNotificationTrigger(
                dateMatching: dateComponents(for: nextDueDate, hour: 9, minute: 0),
                repeats: false
            )
            let request = UNNotificationRequest(
                identifier: "\(record.id.uuidString)-sameDay",
                content: content,
                trigger: trigger
            )
            center.add(request)
        }

        if let nextOccurrence = nextOccurrenceDate(after: nextDueDate, frequency: record.frequency, interval: record.customInterval),
           nextOccurrence > Date() {
            let content = UNMutableNotificationContent()
            content.title = "🐾 Health Reminder"
            content.body = "\(recordTitle) is coming up soon."
            content.sound = .default

            let trigger = UNCalendarNotificationTrigger(
                dateMatching: dateComponents(for: nextOccurrence, hour: 9, minute: 0),
                repeats: false
            )
            let request = UNNotificationRequest(
                identifier: "\(record.id.uuidString)-nextOccurrence",
                content: content,
                trigger: trigger
            )
            center.add(request)
        }
    }

    func cancelReminders(for recordId: UUID) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [
            "\(recordId.uuidString)-dayBefore",
            "\(recordId.uuidString)-sameDay",
            "\(recordId.uuidString)-nextOccurrence"
        ])
    }

    private func dateComponents(for date: Date, hour: Int, minute: Int) -> DateComponents {
        var components = Calendar.current.dateComponents([.year, .month, .day], from: date)
        components.hour = hour
        components.minute = minute
        components.second = 0
        return components
    }

    private func nextOccurrenceDate(after date: Date, frequency: TaskFrequency, interval: Int) -> Date? {
        let calendar = Calendar.current
        switch frequency {
        case .hourly:
            return calendar.date(byAdding: .hour, value: interval, to: date)
        case .daily:
            return calendar.date(byAdding: .day, value: interval, to: date)
        case .weekly:
            return calendar.date(byAdding: .day, value: interval * 7, to: date)
        case .monthly:
            return calendar.date(byAdding: .month, value: interval, to: date)
        case .yearly:
            return calendar.date(byAdding: .year, value: interval, to: date)
        case .custom:
            return calendar.date(byAdding: .day, value: interval, to: date)
        }
    }
}
