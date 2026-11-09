import AppKit
import UserNotifications

final class AppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        UNUserNotificationCenter.current().delegate = self
        CountdownActions.cleanUpImages()
        Task { @MainActor in
            _ = await NotificationScheduler.requestAuthorization()
            CountdownActions.refreshSideEffects()
        }
    }

    func applicationDidBecomeActive(_ notification: Notification) {
        // Keeps recurring reminders topped up (the system allows 64 pending).
        Task { @MainActor in await NotificationScheduler.reschedule(SharedStore.fetchItems()) }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { false }

    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        [.banner, .list, .sound]
    }

    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async {
        let idString = response.notification.request.content.userInfo["countdownID"] as? String
        await MainActor.run {
            if let idString, let id = UUID(uuidString: idString) { AppModel.shared.reveal(id) }
            NSApp.activate()
        }
    }
}
