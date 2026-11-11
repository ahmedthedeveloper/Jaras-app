import ActivityKit
import Foundation

/// Defines the data payload for the Food-Delivery-Style 3-Minute Countdown Live Activity & Dynamic Island.
struct JarasActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var isStarted: Bool
        var statusText: String
    }

    /// 1-based lecture ordinal of the day (e.g. 2 -> "الحصة الثانية")
    var ordinal: Int
    /// Subject title (e.g. "الرياضيات")
    var title: String
    /// Optional classroom/hall
    var location: String
    /// Start of the 3-minute countdown window
    var countdownStart: Date
    /// Exact timestamp when the class begins
    var classBegin: Date
}
