import Foundation

struct Recurrence: Codable, Hashable, Sendable {
    enum Frequency: String, Codable, CaseIterable, Identifiable, Sendable {
        case daily, weekly, monthly, yearly
        var id: String { rawValue }

        var component: Calendar.Component {
            switch self {
            case .daily: .day
            case .weekly: .weekOfYear
            case .monthly: .month
            case .yearly: .year
            }
        }
    }

    var frequency: Frequency = .yearly
    /// Every N units (>= 1).
    var interval: Int = 1
    /// Weekly only: weekdays (1 = Sunday ... 7 = Saturday). Empty = the anchor's weekday.
    var weekdays: Set<Int> = []
    /// Optional last day of the series (inclusive).
    var endDate: Date?

    private var step: Int { max(1, interval) }
    private var usesWeekdays: Bool { frequency == .weekly && !weekdays.isEmpty }

    /// First occurrence strictly after `date`. The anchor itself is the first occurrence.
    func nextOccurrence(after date: Date, anchor: Date, calendar: Calendar = .current) -> Date? {
        let result: Date?
        if anchor > date {
            result = usesWeekdays ? weekdayScan(from: anchor, anchor: anchor, forward: true, inclusive: true, calendar: calendar) : anchor
        } else if usesWeekdays {
            result = weekdayScan(from: date, anchor: anchor, forward: true, inclusive: false, calendar: calendar)
        } else {
            let diff = calendar.dateComponents([frequency.component], from: anchor, to: date).value(for: frequency.component) ?? 0
            var n = max(0, diff / step - 1)
            var found: Date?
            for _ in 0..<64 {
                guard let candidate = calendar.date(byAdding: frequency.component, value: n * step, to: anchor) else { break }
                if candidate > date { found = candidate; break }
                n += 1
            }
            result = found
        }
        guard let result else { return nil }
        if let endDate, result > calendar.endOfDay(for: endDate) { return nil }
        return result
    }

    /// Last occurrence strictly before `date` (nil if `date` is the first one).
    func previousOccurrence(before date: Date, anchor: Date, calendar: Calendar = .current) -> Date? {
        guard date > anchor else { return nil }
        if usesWeekdays {
            return weekdayScan(from: date, anchor: anchor, forward: false, inclusive: false, calendar: calendar)
        }
        let diff = calendar.dateComponents([frequency.component], from: anchor, to: date).value(for: frequency.component) ?? 0
        var n = diff / step + 1
        while n >= 0 {
            if let candidate = calendar.date(byAdding: frequency.component, value: n * step, to: anchor), candidate < date {
                return candidate
            }
            n -= 1
        }
        return nil
    }

    /// Upcoming occurrences after `date`, at most `limit`.
    func occurrences(after date: Date, anchor: Date, limit: Int, calendar: Calendar = .current) -> [Date] {
        var result: [Date] = []
        var cursor = date
        while result.count < limit, let next = nextOccurrence(after: cursor, anchor: anchor, calendar: calendar) {
            result.append(next)
            cursor = next
        }
        return result
    }

    private func weekdayScan(from date: Date, anchor: Date, forward: Bool, inclusive: Bool, calendar: Calendar) -> Date? {
        let time = calendar.dateComponents([.hour, .minute, .second], from: anchor)
        guard let anchorWeek = calendar.dateInterval(of: .weekOfYear, for: anchor)?.start else { return nil }
        var day = calendar.startOfDay(for: date)
        let maxDays = step * 7 * 2 + 8
        for _ in 0..<maxDays {
            if weekdays.contains(calendar.component(.weekday, from: day)),
               let weekStart = calendar.dateInterval(of: .weekOfYear, for: day)?.start {
                let weeks = calendar.dateComponents([.weekOfYear], from: anchorWeek, to: weekStart).weekOfYear ?? 0
                if weeks >= 0, weeks % step == 0,
                   let candidate = calendar.date(bySettingHour: time.hour ?? 0, minute: time.minute ?? 0, second: time.second ?? 0, of: day),
                   candidate >= anchor {
                    let ok = forward ? (inclusive ? candidate >= date : candidate > date) : candidate < date
                    if ok { return candidate }
                }
            }
            guard let next = calendar.date(byAdding: .day, value: forward ? 1 : -1, to: day) else { return nil }
            if !forward, next < calendar.startOfDay(for: anchor) { return nil }
            day = next
        }
        return nil
    }

    var localizedDescription: String {
        switch (frequency, step) {
        case (.daily, 1): return String(localized: "Every day")
        case (.weekly, 1): return String(localized: "Every week")
        case (.monthly, 1): return String(localized: "Every month")
        case (.yearly, 1): return String(localized: "Every year")
        case (.daily, let n): return String(localized: "Every \(n) days")
        case (.weekly, let n): return String(localized: "Every \(n) weeks")
        case (.monthly, let n): return String(localized: "Every \(n) months")
        case (.yearly, let n): return String(localized: "Every \(n) years")
        }
    }
}

extension Calendar {
    func endOfDay(for date: Date) -> Date {
        let start = startOfDay(for: date)
        return self.date(byAdding: DateComponents(day: 1, second: -1), to: start) ?? date
    }
}
