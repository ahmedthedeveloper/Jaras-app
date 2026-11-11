import Foundation
import UserNotifications

/// Schedules both the 3-minute pre-class Bell Alert and the 0-minute "Class Started" notification
/// for upcoming lectures in the user's calendar.
@MainActor
final class LectureScheduler {
    static let shared = LectureScheduler()
    static let leadTime: TimeInterval = 3 * 60 // 3 minutes before class

    private var foregroundWatchTimer: Timer?
    private var firedLectureIds: Set<String> = []
    private var lastScheduledSignature: String = ""

    private init() {}

    func scheduleUpcoming(lectures: [Lecture]) {
        let now = Date()
        // iOS allows up to 64 pending local notifications; schedule the next 28 upcoming lectures (56 requests)
        let upcoming = Array(
            lectures
                .filter { $0.begin > now }
                .sorted { $0.begin < $1.begin }
                .prefix(28)
        )

        //Always keep the 1-second watcher updated with the latest upcoming lectures
        startForegroundWatcher(lectures: upcoming)

        // Avoid cancelling and re-adding identical pending notifications every 10 seconds
        let signature = upcoming.map { "\($0.id)_\($0.ordinal)_\(Int($0.begin.timeIntervalSince1970))" }.joined(separator: "|")
        guard signature != lastScheduledSignature else { return }
        lastScheduledSignature = signature

        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()

        for lecture in upcoming {
            // 1. Schedule T-3m Bell Alert
            let alertDelay = lecture.alertTime.timeIntervalSince(now)
            if alertDelay > 1.0 {
                let alertContent = UNMutableNotificationContent()
                alertContent.title = "🔔 بـدء \(Ar.lecture(lecture.ordinal))"
                var meta = "تبدأ \(Ar.time(lecture.begin))"
                if !lecture.location.isEmpty {
                    meta += " · \(lecture.location)"
                }
                alertContent.subtitle = lecture.title
                alertContent.body = "\(meta) — اضغط لفتح جرس الحصص"
                alertContent.sound = NotificationManager.notificationSound()
                alertContent.categoryIdentifier = NotificationManager.alertCategoryId
                alertContent.userInfo = [
                    "ordinal": lecture.ordinal,
                    "title": lecture.title,
                    "location": lecture.location,
                    "begin": lecture.begin.timeIntervalSince1970,
                    "isPreAlert": true
                ]
                if #available(iOS 15.0, *) {
                    alertContent.interruptionLevel = .active
                    alertContent.relevanceScore = 1.0
                }

                let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(1.0, alertDelay), repeats: false)
                let req = UNNotificationRequest(
                    identifier: "jaras.alert.\(lecture.id)",
                    content: alertContent,
                    trigger: trigger
                )
                center.add(req)
            }

            // 2. Schedule T-0m "Class Started" Notification
            let startDelay = lecture.begin.timeIntervalSince(now)
            if startDelay > 1.0 {
                let startContent = UNMutableNotificationContent()
                startContent.title = "بدأت \(Ar.lecture(lecture.ordinal)) الآن"
                startContent.body = "\(lecture.title) · بالتوفيق والنجاح!"
                startContent.sound = NotificationManager.notificationSound()
                startContent.userInfo = [
                    "ordinal": lecture.ordinal,
                    "title": lecture.title,
                    "begin": lecture.begin.timeIntervalSince1970,
                    "isPreAlert": false
                ]
                if #available(iOS 15.0, *) {
                    startContent.interruptionLevel = .active
                }

                let startTrigger = UNTimeIntervalNotificationTrigger(timeInterval: max(1.0, startDelay), repeats: false)
                let startReq = UNNotificationRequest(
                    identifier: "jaras.start.\(lecture.id)",
                    content: startContent,
                    trigger: startTrigger
                )
                center.add(startReq)
            }
        }
    }

    private func startForegroundWatcher(lectures: [Lecture]) {
        foregroundWatchTimer?.invalidate()
        foregroundWatchTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self = self else { return }
                let now = Date()
                for lecture in lectures {
                    if now >= lecture.alertTime && now < lecture.begin && !self.firedLectureIds.contains(lecture.id) {
                        self.firedLectureIds.insert(lecture.id)
                        NotificationManager.shared.triggerPopup(for: lecture, playChime: true)
                    }
                }
            }
        }
    }
}
