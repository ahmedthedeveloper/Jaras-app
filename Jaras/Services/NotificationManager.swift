import Foundation
import SwiftUI
import UIKit
import UserNotifications

/// Handles iOS notification permissions, 3-minute pre-class alerts,
/// custom bell sound, rich notification categories, and the "Class Started" notification.
@MainActor
final class NotificationManager: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationManager()

    static let alertCategoryId = "JARAS_BELL_ALERT"
    static let readyActionId = "JARAS_READY_ACTION"

    @Published var isAuthorized: Bool = false
    @Published var activePopupLecture: Lecture?

    override private init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
        registerCategories()
        Task { await refreshAuthorizationStatus() }
    }

    static func notificationSound() -> UNNotificationSound {
        if Bundle.main.url(forResource: "bell", withExtension: "wav") != nil {
            return UNNotificationSound(named: UNNotificationSoundName("bell.wav"))
        }
        return .default
    }

    func registerCategories() {
        let readyAction = UNNotificationAction(
            identifier: Self.readyActionId,
            title: "حاضر، أنا جاهز!",
            options: [.foreground]
        )
        let category = UNNotificationCategory(
            identifier: Self.alertCategoryId,
            actions: [readyAction],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )
        UNUserNotificationCenter.current().setNotificationCategories([category])
    }

    func refreshAuthorizationStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        isAuthorized = (settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional)
    }

    func requestPermission() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(
                options: [.alert, .sound, .badge]
            )
            await refreshAuthorizationStatus()
            return granted
        } catch {
            return false
        }
    }

    /// Triggers the in-app full-screen 3D Green Bell Pop-up immediately (and plays chime).
    /// If the app is currently in the background/locked, also posts an immediate banner and starts the Live Activity.
    func triggerPopup(for lecture: Lecture, playChime: Bool = true) {
        activePopupLecture = lecture
        if playChime {
            SoundManager.shared.playBellChime()
        }

        if UIApplication.shared.applicationState != .active {
            postImmediatePreAlertBanner(for: lecture)
            LiveActivityManager.shared.startDeliveryTimer(
                ordinal: lecture.ordinal,
                title: lecture.title,
                location: lecture.location,
                begin: lecture.begin
            )
        }
    }

    /// Posts an immediate high-priority banner notification when T-3m is reached while backgrounded.
    func postImmediatePreAlertBanner(for lecture: Lecture) {
        let alertContent = UNMutableNotificationContent()
        alertContent.title = "🔔 بـدء \(Ar.lecture(lecture.ordinal))"
        var meta = "تبدأ \(Ar.time(lecture.begin))"
        if !lecture.location.isEmpty {
            meta += " · \(lecture.location)"
        }
        alertContent.subtitle = lecture.title
        alertContent.body = "\(meta) — اضغط لفتح جرس الحصص"
        alertContent.sound = Self.notificationSound()
        alertContent.categoryIdentifier = Self.alertCategoryId
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

        let req = UNNotificationRequest(
            identifier: "jaras.alert.now.\(lecture.id)",
            content: alertContent,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(req)
    }

    /// Called when the user closes the 3D Green Bell Pop-up: dismisses alert banner and starts the 3-min delivery timer.
    func closePopupAndStartDeliveryTimer() {
        guard let lecture = activePopupLecture else { return }
        activePopupLecture = nil
        SoundManager.shared.stop()

        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [
            "jaras.alert.\(lecture.id)",
            "jaras.alert.now.\(lecture.id)"
        ])
        LiveActivityManager.shared.startDeliveryTimer(
            ordinal: lecture.ordinal,
            title: lecture.title,
            location: lecture.location,
            begin: lecture.begin
        )
    }

    /// Posts the simple notification when the 3-minute countdown finishes and class begins.
    func postClassStartedNow(ordinal: Int, title: String) {
        let subject = title.isEmpty ? "الحصة" : title
        let content = UNMutableNotificationContent()
        content.title = "بدأت \(Ar.lecture(ordinal)) الآن"
        content.body = "\(subject) · بالتوفيق والنجاح!"
        content.sound = Self.notificationSound()
        if #available(iOS 15.0, *) {
            content.interruptionLevel = .active
        }

        let request = UNNotificationRequest(
            identifier: "jaras.started.\(ordinal)",
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - UNUserNotificationCenterDelegate

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        let userInfo = notification.request.content.userInfo
        if let ordinal = userInfo["ordinal"] as? Int,
           let title = userInfo["title"] as? String,
           let beginTs = userInfo["begin"] as? TimeInterval,
           let isPreAlert = userInfo["isPreAlert"] as? Bool,
           isPreAlert {
            let location = (userInfo["location"] as? String) ?? ""
            let beginDate = Date(timeIntervalSince1970: beginTs)
            let lecture = Lecture(
                id: notification.request.identifier,
                title: title,
                location: location,
                begin: beginDate,
                end: beginDate.addingTimeInterval(45 * 60),
                calendarId: "",
                colorHex: 0x10B981,
                ordinal: ordinal
            )
            await MainActor.run {
                self.activePopupLecture = lecture
                SoundManager.shared.playBellChime()
            }
        }
        return [.banner, .list, .sound]
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        let userInfo = response.notification.request.content.userInfo
        guard let ordinal = userInfo["ordinal"] as? Int,
              let title = userInfo["title"] as? String,
              let beginTs = userInfo["begin"] as? TimeInterval else {
            return
        }
        let location = (userInfo["location"] as? String) ?? ""
        let beginDate = Date(timeIntervalSince1970: beginTs)

        await MainActor.run {
            if response.actionIdentifier == Self.readyActionId ||
               response.actionIdentifier == UNNotificationDismissActionIdentifier {
                // User dismissed the banner or tapped "حاضر، أنا جاهز!" -> start 3-min delivery timer
                LiveActivityManager.shared.startDeliveryTimer(
                    ordinal: ordinal,
                    title: title,
                    location: location,
                    begin: beginDate
                )
            } else {
                // User tapped the notification -> show the full-screen 3D Green Bell Pop-up
                let lecture = Lecture(
                    id: response.notification.request.identifier,
                    title: title,
                    location: location,
                    begin: beginDate,
                    end: beginDate.addingTimeInterval(45 * 60),
                    calendarId: "",
                    colorHex: 0x10B981,
                    ordinal: ordinal
                )
                self.triggerPopup(for: lecture, playChime: false)
            }
        }
    }
}
