import Foundation

enum CountdownMode: String, Codable, CaseIterable, Identifiable, Sendable {
    case countdown, countUp
    var id: String { rawValue }
}

/// What a non-repeating countdown does once its target has passed.
enum EndBehavior: String, Codable, CaseIterable, Identifiable, Sendable {
    case complete, countUp
    var id: String { rawValue }
}

enum WidgetStyle: String, Codable, CaseIterable, Identifiable, Sendable {
    case poster, minimal, ring, card
    var id: String { rawValue }

    var localizedName: String {
        switch self {
        case .poster: String(localized: "Poster")
        case .minimal: String(localized: "Minimal")
        case .ring: String(localized: "Ring")
        case .card: String(localized: "Card")
        }
    }
}

/// Value snapshot of a countdown. Everything time-related is derived from here.
struct CountdownItem: Identifiable, Hashable, Sendable {
    var id: UUID = UUID()
    var title: String = ""
    var notes: String = ""
    var targetDate: Date = Date().addingTimeInterval(7 * 86_400)
    var isAllDay: Bool = false
    var mode: CountdownMode = .countdown
    var afterEnd: EndBehavior = .complete
    var style: WidgetStyle = .poster
    /// Empty = automatic (text color follows the background).
    var accentHex: String = ""
    var icon: IconSpec = .symbol("hourglass")
    var background: BackgroundSpec = .gradient(GradientPreset.default.id)
    var recurrence: Recurrence?
    var reminders: [Reminder] = []
    var isArchived: Bool = false
    var createdAt: Date = Date()
    var sortOrder: Int = 0

    var hasCustomAccent: Bool { !accentHex.isEmpty }

    /// Count down to future dates (and to the next occurrence of repeating ones), count up from past dates.
    static func autoMode(date: Date, recurrence: Recurrence?, now: Date = .now) -> CountdownMode {
        recurrence != nil || date > now ? .countdown : .countUp
    }

    var displayTitle: String { title.isEmpty ? String(localized: "Untitled") : title }

    /// The moment the countdown targets at `now` (next occurrence for recurring ones).
    func effectiveTarget(at now: Date = .now) -> Date {
        guard mode == .countdown, let recurrence else { return targetDate }
        return recurrence.nextOccurrence(after: now, anchor: targetDate) ?? targetDate
    }

    func phase(at now: Date = .now) -> CountdownPhase {
        switch mode {
        case .countUp:
            if targetDate > now { return .counting(target: targetDate, start: createdAt) }
            return .countingUp(since: targetDate)
        case .countdown:
            let target = effectiveTarget(at: now)
            if target > now {
                let previous = recurrence?.previousOccurrence(before: target, anchor: targetDate)
                let start = min(previous ?? createdAt, now)
                return .counting(target: target, start: start)
            }
            return afterEnd == .countUp ? .countingUp(since: target) : .finished(at: target)
        }
    }

    var isFinished: Bool {
        if case .finished = phase() { return true }
        return false
    }

    /// Key used to order lists: closest upcoming first, then count-ups, then finished.
    func sortKey(at now: Date = .now) -> (Int, TimeInterval) {
        switch phase(at: now) {
        case .counting(let target, _): (0, target.timeIntervalSince(now))
        case .countingUp(let since): (1, now.timeIntervalSince(since))
        case .finished(let at): (2, now.timeIntervalSince(at))
        }
    }
}

enum CountdownPhase: Hashable, Sendable {
    /// Counting down to `target`; `start` is used for progress.
    case counting(target: Date, start: Date)
    /// Counting up from `since`.
    case countingUp(since: Date)
    /// Non-recurring countdown that has passed.
    case finished(at: Date)
}
