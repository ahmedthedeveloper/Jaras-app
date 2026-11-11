import ActivityKit
import Foundation
import UserNotifications

/// Manages the Food-Delivery-Style 3-Minute Countdown Live Activity (Dynamic Island + Lock Screen)
/// AND a fallback progress-bar notification in Notification Center.
@MainActor
final class LiveActivityManager: ObservableObject {
    static let shared = LiveActivityManager()

    private var currentActivity: Activity<JarasActivityAttributes>?
    private var countdownTimer: Timer?

    private init() {}

    /// Starts the 3-minute delivery-style countdown timer after the pop-up is closed (or when triggered).
    func startDeliveryTimer(ordinal: Int, title: String, location: String, begin: Date) {
        let now = Date()
        guard begin > now else {
            finishTimerAndAnnounceStart(ordinal: ordinal, title: title)
            return
        }

        stopAllTimers()

        let subject = title.isEmpty ? "حصة" : title
        let attributes = JarasActivityAttributes(
            ordinal: ordinal,
            title: subject,
            location: location,
            countdownStart: now,
            classBegin: begin
        )
        let initialState = JarasActivityAttributes.ContentState(
            isStarted: false,
            statusText: "متبقي \(Ar.countdownText(secondsRemaining: begin.timeIntervalSince(now)))"
        )

        // 1. Start iOS 16.1+ Live Activity & Dynamic Island (native 60fps progress bar & chronometer)
        if ActivityAuthorizationInfo().areActivitiesEnabled {
            do {
                // End any stale activities first
                for activity in Activity<JarasActivityAttributes>.activities {
                    Task { await activity.end(nil, dismissalPolicy: .immediate) }
                }

                let content = ActivityContent(state: initialState, staleDate: begin)
                currentActivity = try Activity.request(
                    attributes: attributes,
                    content: content,
                    pushType: nil
                )
            } catch {
                // Fallback to standard notification progress updates below
            }
        }

        // 2. Also update a sticky notification in Notification Center with a visual progress bar
        let totalDuration = max(60.0, begin.timeIntervalSince(now))
        postProgressNotification(
            ordinal: ordinal,
            title: subject,
            begin: begin,
            totalDuration: totalDuration,
            remaining: begin.timeIntervalSince(now)
        )

        // 3. Step the progress bar every 3 seconds and auto-complete at `begin`
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self = self else { return }
                let rem = begin.timeIntervalSince(Date())
                if rem <= 0.5 {
                    self.finishTimerAndAnnounceStart(ordinal: ordinal, title: subject)
                } else {
                    self.postProgressNotification(
                        ordinal: ordinal,
                        title: subject,
                        begin: begin,
                        totalDuration: totalDuration,
                        remaining: rem
                    )
                    if let activity = self.currentActivity {
                        let updatedState = JarasActivityAttributes.ContentState(
                            isStarted: false,
                            statusText: "متبقي \(Ar.countdownText(secondsRemaining: rem))"
                        )
                        await activity.update(ActivityContent(state: updatedState, staleDate: begin))
                    }
                }
            }
        }
    }

    /// Removes the 3-minute timer notification/Live Activity and posts the simple "Class Started" notification.
    func finishTimerAndAnnounceStart(ordinal: Int, title: String) {
        stopAllTimers()

        // Remove the sticky countdown timer notification
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: ["jaras.delivery.timer"])
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["jaras.delivery.timer"])

        // End Live Activity immediately
        Task {
            for activity in Activity<JarasActivityAttributes>.activities {
                await activity.end(nil, dismissalPolicy: .immediate)
            }
            currentActivity = nil
        }

        // Post the simple "Class Started" notification
        NotificationManager.shared.postClassStartedNow(ordinal: ordinal, title: title)
    }

    func stopAllTimers() {
        countdownTimer?.invalidate()
        countdownTimer = nil
    }

    private func postProgressNotification(
        ordinal: Int,
        title: String,
        begin: Date,
        totalDuration: TimeInterval,
        remaining: TimeInterval
    ) {
        let elapsed = max(0, totalDuration - remaining)
        let fraction = min(1.0, max(0.0, elapsed / totalDuration))
        let filledBlocks = Int(round(fraction * 12))
        let bar = String(repeating: "🟩", count: filledBlocks) + String(repeating: "⬜", count: max(0, 12 - filledBlocks))
        let pct = Ar.num(Int(round(fraction * 100)))

        let content = UNMutableNotificationContent()
        content.title = "اقتراب موعد \(Ar.lecture(ordinal))"
        content.subtitle = "\(title) · متبقي \(Ar.countdownText(secondsRemaining: remaining))"
        content.body = "\(bar)  \(pct)٪"
        content.sound = nil // Silent update just like delivery apps
        if #available(iOS 15.0, *) {
            content.interruptionLevel = .passive
            content.relevanceScore = 1.0
        }

        let request = UNNotificationRequest(
            identifier: "jaras.delivery.timer",
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)
    }
}
