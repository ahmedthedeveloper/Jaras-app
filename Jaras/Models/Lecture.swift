import Foundation
import SwiftUI

struct Lecture: Identifiable, Equatable, Codable {
    let id: String
    let title: String
    let location: String
    let begin: Date
    let end: Date
    let calendarId: String
    let colorHex: UInt32
    var ordinal: Int

    var durationMinutes: Int {
        max(1, Int(round(end.timeIntervalSince(begin) / 60.0)))
    }

    var alertTime: Date {
        begin.addingTimeInterval(-3 * 60) // 3 minutes before class starts
    }

    func isOngoing(at now: Date = Date()) -> Bool {
        now >= begin && now < end
    }

    func isPast(at now: Date = Date()) -> Bool {
        now >= end
    }

    func progressFraction(at now: Date = Date()) -> Double {
        let total = end.timeIntervalSince(begin)
        guard total > 0 else { return 0 }
        let elapsed = now.timeIntervalSince(begin)
        return min(1.0, max(0.0, elapsed / total))
    }
}

struct CalendarSource: Identifiable, Equatable {
    let id: String
    let title: String
    let account: String
    let colorHex: UInt32
    var isSelected: Bool
}
