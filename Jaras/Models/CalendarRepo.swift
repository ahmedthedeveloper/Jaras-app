import EventKit
import Foundation
import SwiftUI

/// Reads synced Google Calendar / iOS Calendar events via EventKit, numbers each day's classes
/// in chronological order, and schedules upcoming 3-minute bell alerts.
@MainActor
final class CalendarRepo: ObservableObject {
    private let store = EKEventStore()
    private let prefsKey = "excluded_calendars"

    @Published var hasPermission: Bool = false
    @Published var calendars: [CalendarSource] = []
    @Published var lecturesByDay: [Date: [Lecture]] = [:]
    @Published var nextLecture: Lecture?

    init() {
        checkAuthorization()
    }

    func checkAuthorization() {
        let status = EKEventStore.authorizationStatus(for: .event)
        if #available(iOS 17.0, *) {
            hasPermission = (status == .fullAccess)
        } else {
            hasPermission = (status == .authorized)
        }
        if hasPermission {
            reload()
        }
    }

    func requestAccess() async -> Bool {
        do {
            let granted: Bool
            if #available(iOS 17.0, *) {
                granted = try await store.requestFullAccessToEvents()
            } else {
                granted = try await store.requestAccess(to: .event)
            }
            hasPermission = granted
            if granted {
                reload()
            }
            return granted
        } catch {
            hasPermission = false
            return false
        }
    }

    func isCalendarIncluded(_ id: String) -> Bool {
        let excluded = UserDefaults.standard.stringArray(forKey: prefsKey) ?? []
        return !excluded.contains(id)
    }

    func toggleCalendar(_ id: String) {
        var excluded = Set(UserDefaults.standard.stringArray(forKey: prefsKey) ?? [])
        if excluded.contains(id) {
            excluded.remove(id)
        } else {
            excluded.insert(id)
        }
        UserDefaults.standard.set(Array(excluded), forKey: prefsKey)
        reload()
    }

    func reload() {
        guard hasPermission else { return }

        let ekCalendars = store.calendars(for: .event)
        calendars = ekCalendars.map { cal in
            CalendarSource(
                id: cal.calendarIdentifier,
                title: cal.title.isEmpty ? "تقويم" : cal.title,
                account: cal.source?.title ?? "حساب التقويم",
                colorHex: Self.hexFromCGColor(cal.cgColor),
                isSelected: isCalendarIncluded(cal.calendarIdentifier)
            )
        }

        let activeEkCalendars = ekCalendars.filter { isCalendarIncluded($0.calendarIdentifier) }
        guard !activeEkCalendars.isEmpty else {
            lecturesByDay = [:]
            nextLecture = nil
            return
        }

        let now = Date()
        let startWindow = Ar.dayStart(now)
        let endWindow = Ar.addDays(startWindow, 14)

        let predicate = store.predicateForEvents(
            withStart: startWindow,
            end: endWindow,
            calendars: activeEkCalendars
        )
        let rawEvents = store.events(matching: predicate)
            .filter { !$0.isAllDay && $0.endDate > $0.startDate }
            .sorted { $0.startDate < $1.startDate }

        var grouped: [Date: [Lecture]] = [:]
        for ev in rawEvents {
            let day = Ar.dayStart(ev.startDate)
            var list = grouped[day] ?? []
            let ordinal = list.count + 1
            let trimmedTitle = (ev.title ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            let lecture = Lecture(
                id: "\(ev.eventIdentifier ?? UUID().uuidString)_\( Int(ev.startDate.timeIntervalSince1970) )",
                title: trimmedTitle.isEmpty ? "حصة" : trimmedTitle,
                location: (ev.location ?? "").trimmingCharacters(in: .whitespacesAndNewlines),
                begin: ev.startDate,
                end: ev.endDate,
                calendarId: ev.calendar.calendarIdentifier,
                colorHex: Self.hexFromCGColor(ev.calendar.cgColor),
                ordinal: ordinal
            )
            list.append(lecture)
            grouped[day] = list
        }

        lecturesByDay = grouped
        nextLecture = grouped.values
            .flatMap { $0 }
            .filter { $0.begin > now }
            .sorted { $0.begin < $1.begin }
            .first

        // Schedule local notifications & background triggers for upcoming classes
        LectureScheduler.shared.scheduleUpcoming(lectures: grouped.values.flatMap { $0 })
    }

    private static func hexFromCGColor(_ cgColor: CGColor?) -> UInt32 {
        guard let components = cgColor?.components, components.count >= 3 else {
            return 0x10B981
        }
        let r = UInt32(max(0, min(255, Int(components[0] * 255))))
        let g = UInt32(max(0, min(255, Int(components[1] * 255))))
        let b = UInt32(max(0, min(255, Int(components[2] * 255))))
        return (r << 16) | (g << 8) | b
    }
}
