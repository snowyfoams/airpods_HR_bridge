import Foundation
import UserNotifications

@MainActor
final class HeartRateReminderManager: NSObject, UNUserNotificationCenterDelegate {
    private let highHeartRateThreshold = 120
    private let notificationCooldown: TimeInterval = 5 * 60
    private var lastNotificationDate: Date?
    private var wasBelowResetThreshold = true

    override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }

    func handle(bpm: Int) {
        guard bpm >= highHeartRateThreshold else {
            if bpm < highHeartRateThreshold - 10 {
                wasBelowResetThreshold = true
            }
            return
        }

        let now = Date()
        let cooldownElapsed = lastNotificationDate.map { now.timeIntervalSince($0) >= notificationCooldown } ?? true
        guard wasBelowResetThreshold || cooldownElapsed else { return }

        wasBelowResetThreshold = false
        lastNotificationDate = now

        Task {
            await sendHighHeartRateNotification(bpm: bpm)
        }
    }

    func reset() {
        wasBelowResetThreshold = true
        lastNotificationDate = nil
    }

    private func sendHighHeartRateNotification(bpm: Int) async {
        let center = UNUserNotificationCenter.current()

        do {
            let settings = await center.notificationSettings()
            if settings.authorizationStatus == .notDetermined {
                let granted = try await center.requestAuthorization(options: [.alert, .sound])
                guard granted else { return }
            } else {
                guard settings.authorizationStatus == .authorized ||
                        settings.authorizationStatus == .provisional ||
                        settings.authorizationStatus == .ephemeral else { return }
            }

            let content = UNMutableNotificationContent()
            content.title = "High heart rate"
            content.body = "\(bpm) BPM detected. Check your intensity."
            content.sound = .default

            let request = UNNotificationRequest(identifier: "high-heart-rate-\(Int(Date().timeIntervalSince1970))",
                                                content: content,
                                                trigger: nil)
            try await center.add(request)
        } catch {
            // Notification failures should not interrupt heart-rate monitoring.
        }
    }

    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter,
                                            willPresent notification: UNNotification,
                                            withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }
}
