import Foundation
import SwiftData

/// Persistent record. Complex values are stored as JSON blobs so the schema
/// stays simple and future-proof; use `item` for a Sendable value snapshot.
@Model
final class Countdown {
    var id: UUID = UUID()
    var title: String = ""
    var notes: String = ""
    var targetDate: Date = Date()
    var isAllDay: Bool = false
    var modeRaw: String = CountdownMode.countdown.rawValue
    var afterEndRaw: String = EndBehavior.complete.rawValue
    var styleRaw: String = WidgetStyle.poster.rawValue
    var accentHex: String = ""
    var iconData: Data?
    var backgroundData: Data?
    var recurrenceData: Data?
    var remindersData: Data?
    var isArchived: Bool = false
    var createdAt: Date = Date()
    var sortOrder: Int = 0

    init(item: CountdownItem) {
        self.id = item.id
        self.createdAt = item.createdAt
        apply(item)
    }

    func apply(_ item: CountdownItem) {
        title = item.title
        notes = item.notes
        targetDate = item.targetDate
        isAllDay = item.isAllDay
        modeRaw = item.mode.rawValue
        afterEndRaw = item.afterEnd.rawValue
        styleRaw = item.style.rawValue
        accentHex = item.accentHex
        iconData = JSON.encode(item.icon)
        backgroundData = JSON.encode(item.background)
        recurrenceData = item.recurrence.flatMap(JSON.encode)
        remindersData = JSON.encode(item.reminders)
        isArchived = item.isArchived
        sortOrder = item.sortOrder
    }

    var item: CountdownItem {
        CountdownItem(
            id: id,
            title: title,
            notes: notes,
            targetDate: targetDate,
            isAllDay: isAllDay,
            mode: CountdownMode(rawValue: modeRaw) ?? .countdown,
            afterEnd: EndBehavior(rawValue: afterEndRaw) ?? .complete,
            style: WidgetStyle(rawValue: styleRaw) ?? .poster,
            accentHex: accentHex,
            icon: iconData.flatMap { JSON.decode(IconSpec.self, from: $0) } ?? .symbol("hourglass"),
            background: backgroundData.flatMap { JSON.decode(BackgroundSpec.self, from: $0) } ?? .gradient(GradientPreset.default.id),
            recurrence: recurrenceData.flatMap { JSON.decode(Recurrence.self, from: $0) },
            reminders: remindersData.flatMap { JSON.decode([Reminder].self, from: $0) } ?? [],
            isArchived: isArchived,
            createdAt: createdAt,
            sortOrder: sortOrder
        )
    }
}

enum JSON {
    static func encode<T: Encodable>(_ value: T) -> Data? { try? JSONEncoder().encode(value) }
    static func decode<T: Decodable>(_ type: T.Type, from data: Data) -> T? { try? JSONDecoder().decode(type, from: data) }
}
