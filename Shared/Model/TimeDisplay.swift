import Foundation

/// How a countdown should be drawn at a given instant.
///
/// Battery strategy: the day count is static text, and the sub-day part is a
/// system-driven `Text(timerInterval:)` that the OS animates without waking the
/// app or the widget. New renders are only needed at day boundaries, which is
/// what `boundaries(after:limit:)` returns for widget timelines.
struct TimeDisplay: Hashable, Sendable {
    enum Kind: Hashable, Sendable { case down, up, done }

    let kind: Kind
    let days: Int
    /// Range for `Text(timerInterval:)` (always shorter than one day).
    let timerRange: ClosedRange<Date>
    /// Range for live progress views (count-down only).
    let progressRange: ClosedRange<Date>?
    /// Target (down / done) or start (up).
    let reference: Date
    /// Static progress 0...1 at render time.
    let fraction: Double

    var isUnderADay: Bool { kind == .down && days == 0 }
}

extension CountdownItem {
    static let day: TimeInterval = 86_400

    func display(at now: Date = .now) -> TimeDisplay {
        switch phase(at: now) {
        case .counting(let target, let start):
            let remaining = target.timeIntervalSince(now)
            let days = max(0, Int(((remaining - 0.5) / Self.day).rounded(.down)))
            let timerEnd = target.addingTimeInterval(-Double(days) * Self.day)
            let total = max(1, target.timeIntervalSince(start))
            let fraction = min(1, max(0, now.timeIntervalSince(start) / total))
            return TimeDisplay(kind: .down, days: days, timerRange: now...max(now, timerEnd),
                               progressRange: start...target, reference: target, fraction: fraction)
        case .countingUp(let since):
            let elapsed = now.timeIntervalSince(since)
            let days = max(0, Int((elapsed / Self.day).rounded(.down)))
            let timerStart = since.addingTimeInterval(Double(days) * Self.day)
            return TimeDisplay(kind: .up, days: days, timerRange: timerStart...timerStart.addingTimeInterval(Self.day),
                               progressRange: nil, reference: since, fraction: (elapsed.truncatingRemainder(dividingBy: Self.day)) / Self.day)
        case .finished(let at):
            let days = max(0, Int((now.timeIntervalSince(at) / Self.day).rounded(.down)))
            return TimeDisplay(kind: .done, days: days, timerRange: now...now, progressRange: nil, reference: at, fraction: 1)
        }
    }

    /// Instants after `now` when the static part of the display changes.
    func boundaries(after now: Date, limit: Int = 40) -> [Date] {
        var dates: [Date] = []
        switch phase(at: now) {
        case .counting(let target, let start):
            let days = max(0, Int((target.timeIntervalSince(now) / Self.day).rounded(.down)))
            for d in stride(from: days, through: 0, by: -1) {
                let date = target.addingTimeInterval(-Double(d) * Self.day)
                if date > now { dates.append(date) }
                if dates.count >= limit { break }
            }
            // Ring style shows static progress; give it a finer cadence for short countdowns.
            if style == .ring {
                let total = target.timeIntervalSince(start)
                let step = max(300, total / 120)
                if step < Self.day {
                    var t = now.addingTimeInterval(step)
                    while t < target, dates.count < limit * 2 { dates.append(t); t.addTimeInterval(step) }
                }
            }
        case .countingUp(let since):
            let days = Int((now.timeIntervalSince(since) / Self.day).rounded(.down))
            for d in (days + 1)...(days + limit) {
                dates.append(since.addingTimeInterval(Double(d) * Self.day))
            }
        case .finished:
            break
        }
        return Array(Set(dates).sorted().prefix(limit))
    }
}
