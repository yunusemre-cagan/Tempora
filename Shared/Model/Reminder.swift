import Foundation

/// A notification fired `offset` seconds before the target (0 = at the moment).
struct Reminder: Codable, Hashable, Identifiable, Sendable {
    var id: UUID = UUID()
    var offset: TimeInterval

    static let presets: [TimeInterval] = [0, 5 * 60, 15 * 60, 3600, 3 * 3600, 86_400, 2 * 86_400, 7 * 86_400]

    var localizedDescription: String {
        offset == 0 ? String(localized: "At time of event") : String(localized: "\(Self.durationText(offset)) before")
    }

    static func durationText(_ seconds: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .full
        formatter.allowedUnits = [.weekOfMonth, .day, .hour, .minute]
        formatter.maximumUnitCount = 2
        return formatter.string(from: seconds) ?? ""
    }
}
