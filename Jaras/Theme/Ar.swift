import Foundation

/// Arabic wording, Eastern Arabic numerals, ordinals, and date/time helpers for «جرس الحصص».
enum Ar {
    static let locale = Locale(identifier: "ar")

    private static let days = [
        "الأحد", "الاثنين", "الثلاثاء", "الأربعاء", "الخميس", "الجمعة", "السبت"
    ]
    private static let daysShort = [
        "أحد", "اثنين", "ثلاثاء", "أربعاء", "خميس", "جمعة", "سبت"
    ]
    private static let months = [
        "يناير", "فبراير", "مارس", "أبريل", "مايو", "يونيو",
        "يوليو", "أغسطس", "سبتمبر", "أكتوبر", "نوفمبر", "ديسمبر"
    ]
    private static let ordinals = [
        "الأولى", "الثانية", "الثالثة", "الرابعة", "الخامسة",
        "السادسة", "السابعة", "الثامنة", "التاسعة", "العاشرة",
        "الحادية عشرة", "الثانية عشرة"
    ]

    /// Converts Western digits (0-9) to Eastern Arabic digits (٠-٩).
    static func digits(_ s: String) -> String {
        let zeroScalar = UnicodeScalar("٠").value
        var out = String.UnicodeScalarView()
        out.reserveCapacity(s.unicodeScalars.count)
        for ch in s.unicodeScalars {
            if ch.value >= 48 && ch.value <= 57 {
                if let eastern = UnicodeScalar(zeroScalar + (ch.value - 48)) {
                    out.append(eastern)
                    continue
                }
            }
            out.append(ch)
        }
        return String(out)
    }

    static func num(_ n: Int) -> String {
        digits(String(n))
    }

    static func two(_ n: Int) -> String {
        digits(n < 10 ? "0\(n)" : "\(n)")
    }

    // MARK: - Dates

    static func dayStart(_ date: Date) -> Date {
        Calendar.current.startOfDay(for: date)
    }

    static func addDays(_ date: Date, _ count: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: count, to: date) ?? date
    }

    static func dayName(_ date: Date) -> String {
        let weekday = Calendar.current.component(.weekday, from: date) // 1 = Sunday
        return days[max(0, min(days.count - 1, weekday - 1))]
    }

    static func dayShort(_ date: Date) -> String {
        let weekday = Calendar.current.component(.weekday, from: date)
        return daysShort[max(0, min(daysShort.count - 1, weekday - 1))]
    }

    static func dayOfMonth(_ date: Date) -> String {
        num(Calendar.current.component(.day, from: date))
    }

    static func fullDate(_ date: Date) -> String {
        let cal = Calendar.current
        let w = cal.component(.weekday, from: date) - 1
        let d = cal.component(.day, from: date)
        let m = cal.component(.month, from: date) - 1
        let y = cal.component(.year, from: date)
        return "\(days[w])، \(num(d)) \(months[m]) \(num(y))"
    }

    static func relativeDay(_ date: Date, now: Date = Date()) -> String {
        let d = dayStart(date)
        let today = dayStart(now)
        if d == today { return "اليوم" }
        if d == addDays(today, 1) { return "غدًا" }
        return dayName(date)
    }

    // MARK: - Clock & Ranges

    static func clock(_ date: Date) -> String {
        let cal = Calendar.current
        var h = cal.component(.hour, from: date) % 12
        if h == 0 { h = 12 }
        let m = cal.component(.minute, from: date)
        return "\(num(h)):\(two(m))"
    }

    static func period(_ date: Date) -> String {
        Calendar.current.component(.hour, from: date) < 12 ? "ص" : "م"
    }

    static func time(_ date: Date) -> String {
        "\(clock(date)) \(period(date))"
    }

    static func range(from start: Date, to end: Date) -> String {
        if period(start) == period(end) {
            return "\(clock(start)) – \(clock(end)) \(period(end))"
        }
        return "\(time(start)) – \(time(end))"
    }

    // MARK: - Ordinals & Wording ("حصة")

    static func ordinal(_ n: Int) -> String {
        if n >= 1 && n <= ordinals.count {
            return ordinals[n - 1]
        }
        return "رقم \(num(n))"
    }

    /// e.g. "الحصة الثانية"
    static func lecture(_ n: Int) -> String {
        "الحصة \(ordinal(n))"
    }

    static func minutes(_ n: Int) -> String {
        if n <= 0 { return "أقل من دقيقة" }
        if n == 1 { return "دقيقة واحدة" }
        if n == 2 { return "دقيقتين" }
        if n <= 10 { return "\(num(n)) دقائق" }
        return "\(num(n)) دقيقة"
    }

    static func hours(_ n: Int) -> String {
        if n == 1 { return "ساعة" }
        if n == 2 { return "ساعتين" }
        if n <= 10 { return "\(num(n)) ساعات" }
        return "\(num(n)) ساعة"
    }

    static func span(minutes mins: Int) -> String {
        if mins < 60 { return minutes(mins) }
        let h = mins / 60
        let m = mins % 60
        return m == 0 ? hours(h) : "\(hours(h)) و\(minutes(m))"
    }

    static func inTime(minutes mins: Int) -> String {
        mins <= 0 ? "الآن" : "بعد \(span(minutes: mins))"
    }

    static func lectureCount(_ n: Int) -> String {
        if n == 0 { return "لا حصص" }
        if n == 1 { return "حصة واحدة" }
        if n == 2 { return "حصتان" }
        if n <= 10 { return "\(num(n)) حصص" }
        return "\(num(n)) حصة"
    }

    static func greeting(now: Date = Date()) -> String {
        let h = Calendar.current.component(.hour, from: now)
        if h >= 5 && h < 12 { return "صباح الخير" }
        if h >= 12 && h < 17 { return "نهارك سعيد" }
        return "مساء الخير"
    }

    static func minutesUntil(_ target: Date, from now: Date = Date()) -> Int {
        let diff = target.timeIntervalSince(now)
        if diff <= 0 { return 0 }
        return Int(ceil(diff / 60.0))
    }

    static func countdownText(secondsRemaining: TimeInterval) -> String {
        if secondsRemaining <= 0 { return "الآن" }
        let totalSecs = Int(ceil(secondsRemaining))
        let m = totalSecs / 60
        let s = totalSecs % 60
        if m == 0 { return "\(num(s)) ثانية" }
        if s == 0 { return minutes(m) }
        return "\(num(m)):\(two(s))"
    }
}
