import Foundation
import UserNotifications

/// Local notifications only. macOS keeps at most 64 pending requests per app,
/// so the nearest ones are scheduled and the list is rebuilt on every change
/// and whenever the app becomes active.
@MainActor
enum NotificationScheduler {
    private static let maxPending = 60
    private static let occurrencesPerItem = 12

    @discardableResult
    static func requestAuthorization() async -> Bool {
        (try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])) ?? false
    }

    static func authorizationStatus() async -> UNAuthorizationStatus {
        await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
    }

    static func reschedule(_ items: [CountdownItem]) async {
        let center = UNUserNotificationCenter.current()
        let status = await center.notificationSettings().authorizationStatus
        guard status == .authorized || status == .provisional else { return }
        center.removeAllPendingNotificationRequests()

        let now = Date()
        var planned: [(fire: Date, item: CountdownItem, occurrence: Date, reminder: Reminder)] = []
        for item in items where !item.isArchived && item.mode == .countdown && !item.reminders.isEmpty {
            let occurrences: [Date]
            if let recurrence = item.recurrence {
                occurrences = recurrence.occurrences(after: now, anchor: item.targetDate, limit: occurrencesPerItem)
            } else {
                occurrences = item.targetDate > now ? [item.targetDate] : []
            }
            for occurrence in occurrences {
                for reminder in item.reminders {
                    let fire = occurrence.addingTimeInterval(-reminder.offset)
                    if fire > now { planned.append((fire, item, occurrence, reminder)) }
                }
            }
        }
        planned.sort { $0.fire < $1.fire }

        for entry in planned.prefix(maxPending) {
            let content = UNMutableNotificationContent()
            content.title = entry.item.displayTitle
            let when = entry.occurrence.formatted(entry.item.isAllDay
                ? .dateTime.day().month(.wide)
                : .dateTime.day().month(.wide).hour().minute())
            content.body = entry.reminder.offset == 0
                ? String(localized: "It's time! 🎉")
                : String(localized: "\(Reminder.durationText(entry.reminder.offset)) to go · \(when)")
            content.sound = .default
            content.threadIdentifier = entry.item.id.uuidString
            content.userInfo = ["countdownID": entry.item.id.uuidString]

            let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: entry.fire)
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            let identifier = "\(entry.item.id.uuidString)-\(Int(entry.occurrence.timeIntervalSince1970))-\(Int(entry.reminder.offset))"
            try? await center.add(UNNotificationRequest(identifier: identifier, content: content, trigger: trigger))
        }
    }
}
