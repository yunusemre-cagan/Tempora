import Foundation

struct CountdownTemplate: Identifiable, Sendable {
    let id: String
    let title: String
    let symbol: String
    let gradient: String
    var mode: CountdownMode = .countdown
    var style: WidgetStyle = .poster
    var recurrence: Recurrence?
    var reminderOffsets: [TimeInterval] = [86_400, 0]
    var target: @Sendable () -> Date = { Calendar.current.date(byAdding: .day, value: 30, to: .now.roundedToHour) ?? .now }

    func makeItem() -> CountdownItem {
        CountdownItem(
            title: id == "blank" ? "" : title,
            targetDate: target(),
            mode: mode,
            style: style,
            icon: .symbol(symbol),
            background: .gradient(gradient),
            recurrence: recurrence,
            reminders: mode == .countdown ? reminderOffsets.map { Reminder(offset: $0) } : []
        )
    }

    static var all: [CountdownTemplate] {
        [
            .init(id: "blank", title: String(localized: "Blank"), symbol: "hourglass", gradient: "midnight"),
            .init(id: "birthday", title: String(localized: "Birthday"), symbol: "birthday.cake.fill", gradient: "berry",
                  recurrence: Recurrence(frequency: .yearly), reminderOffsets: [7 * 86_400, 86_400, 0]),
            .init(id: "newyear", title: String(localized: "New Year"), symbol: "sparkles", gradient: "nebula",
                  recurrence: Recurrence(frequency: .yearly), reminderOffsets: [3600, 0], target: {
                      let cal = Calendar.current
                      let year = cal.component(.year, from: .now) + 1
                      return cal.date(from: DateComponents(year: year, month: 1, day: 1)) ?? .now
                  }),
            .init(id: "vacation", title: String(localized: "Vacation"), symbol: "airplane", gradient: "lagoon",
                  reminderOffsets: [7 * 86_400, 86_400]),
            .init(id: "exam", title: String(localized: "Exam"), symbol: "graduationcap.fill", gradient: "ember",
                  style: .ring, reminderOffsets: [7 * 86_400, 86_400, 3600]),
            .init(id: "anniversary", title: String(localized: "Anniversary"), symbol: "heart.fill", gradient: "rose",
                  recurrence: Recurrence(frequency: .yearly), reminderOffsets: [86_400, 0]),
            .init(id: "deadline", title: String(localized: "Deadline"), symbol: "flag.checkered", gradient: "graphite",
                  style: .minimal, reminderOffsets: [86_400, 3 * 3600]),
            .init(id: "concert", title: String(localized: "Concert"), symbol: "music.note", gradient: "sunset",
                  reminderOffsets: [86_400, 3 * 3600]),
            .init(id: "launch", title: String(localized: "Launch"), symbol: "paperplane.fill", gradient: "ocean",
                  style: .card, reminderOffsets: [86_400, 3600]),
            .init(id: "smokefree", title: String(localized: "Smoke-free"), symbol: "leaf.fill", gradient: "forest",
                  mode: .countUp, style: .ring, target: { .now }),
            .init(id: "together", title: String(localized: "Together"), symbol: "heart.circle.fill", gradient: "peach",
                  mode: .countUp, target: { Calendar.current.date(byAdding: .year, value: -1, to: Calendar.current.startOfDay(for: .now)) ?? .now }),
        ]
    }
}

extension Date {
    var roundedToHour: Date {
        let cal = Calendar.current
        return cal.date(from: cal.dateComponents([.year, .month, .day, .hour], from: self)).map { $0.addingTimeInterval(3600) } ?? self
    }
}
