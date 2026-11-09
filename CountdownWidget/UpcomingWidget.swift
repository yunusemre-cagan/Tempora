import SwiftUI
import WidgetKit

struct UpcomingEntry: TimelineEntry {
    let date: Date
    let items: [CountdownItem]
}

struct UpcomingProvider: TimelineProvider {
    func placeholder(in context: Context) -> UpcomingEntry {
        UpcomingEntry(date: .now, items: [.sample])
    }

    func getSnapshot(in context: Context, completion: @escaping (UpcomingEntry) -> Void) {
        let items = SharedStore.fetchItems().sortedForDisplay()
        completion(UpcomingEntry(date: .now, items: items.isEmpty ? [.sample] : Array(items.prefix(6))))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<UpcomingEntry>) -> Void) {
        let now = Date()
        let items = Array(SharedStore.fetchItems().sortedForDisplay(at: now).prefix(6))
        let boundaries = Set(items.flatMap { $0.boundaries(after: now, limit: 8) }).sorted().prefix(30)
        // Order can change after a boundary, so re-sort per entry.
        let entries = ([now] + boundaries).map { date in
            UpcomingEntry(date: date, items: items.sortedForDisplay(at: date))
        }
        completion(Timeline(entries: entries, policy: boundaries.isEmpty ? .never : .atEnd))
    }
}

struct UpcomingWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "UpcomingWidget", provider: UpcomingProvider()) { entry in
            UpcomingWidgetView(entry: entry)
                .containerBackground(for: .widget) {
                    ZStack {
                        GradientPreset.preset("noir").gradient
                        RadialGradient(colors: [Color(hex: "#5B3FA8").opacity(0.35), .clear], center: .topTrailing, startRadius: 0, endRadius: 320)
                    }
                }
        }
        .configurationDisplayName("Upcoming")
        .description("Your next countdowns at a glance.")
        .supportedFamilies([.systemMedium, .systemLarge, .systemExtraLarge])
    }
}

struct UpcomingWidgetView: View {
    let entry: UpcomingEntry
    @Environment(\.widgetFamily) private var family
    @Environment(\.widgetRenderingMode) private var renderingMode

    var body: some View {
        let limit = family == .systemMedium ? 3 : 6
        let items = Array(entry.items.prefix(limit))
        let palette = FacePalette(foreground: renderingMode == .fullColor ? .white : .primary,
                                  accent: renderingMode == .fullColor ? .white : .primary,
                                  isFullColor: renderingMode == .fullColor)
        VStack(alignment: .leading, spacing: family == .systemMedium ? 6 : 10) {
            if family != .systemMedium {
                HStack {
                    Text("Upcoming").font(.system(size: 15, weight: .bold))
                    Spacer()
                    Image(systemName: "hourglass").font(.system(size: 12, weight: .semibold)).opacity(0.6)
                }
            }
            if items.isEmpty {
                Spacer()
                Text("Create a countdown in the app").font(.system(size: 12)).opacity(0.7).frame(maxWidth: .infinity)
                Spacer()
            } else {
                ForEach(items) { item in
                    Link(destination: URL(string: "countdown://open/\(item.id.uuidString)")!) {
                        UpcomingRow(item: item, date: entry.date, palette: palette, compact: family == .systemMedium)
                    }
                    if item.id != items.last?.id {
                        Rectangle().fill(palette.foreground.opacity(0.1)).frame(height: 1)
                    }
                }
                Spacer(minLength: 0)
            }
        }
        .foregroundStyle(palette.foreground)
        .fontDesign(.rounded)
    }
}

private struct UpcomingRow: View {
    let item: CountdownItem
    let date: Date
    let palette: FacePalette
    let compact: Bool

    var body: some View {
        let d = item.display(at: date)
        HStack(spacing: 10) {
            ZStack {
                Circle().fill(GradientPreset.preset(gradientID).gradient)
                IconBadge(icon: item.icon, palette: FacePalette(foreground: .white, accent: .white, isFullColor: palette.isFullColor), size: compact ? 26 : 30)
            }
            .frame(width: compact ? 26 : 30, height: compact ? 26 : 30)
            VStack(alignment: .leading, spacing: 1) {
                Text(item.displayTitle).font(.system(size: 13, weight: .semibold)).lineLimit(1)
                item.dateCaption(d).font(.system(size: 10, weight: .medium)).opacity(0.6).lineLimit(1)
            }
            Spacer(minLength: 4)
            VStack(alignment: .trailing, spacing: 0) {
                if d.kind == .done {
                    Image(systemName: "checkmark.seal.fill").font(.system(size: 16)).widgetAccentable()
                } else if d.isUnderADay {
                    LiveTimerText(display: d).font(.system(size: 16, weight: .bold)).monospacedDigit().multilineTextAlignment(.trailing)
                } else {
                    HStack(alignment: .firstTextBaseline, spacing: 3) {
                        Text(d.days, format: .number).font(.system(size: 18, weight: .bold)).widgetAccentable()
                        Text(d.shortUnit).font(.system(size: 9, weight: .semibold)).opacity(0.65)
                    }
                    if !compact {
                        LiveTimerText(display: d).font(.system(size: 11, weight: .medium)).monospacedDigit()
                            .multilineTextAlignment(.trailing).opacity(0.7)
                    }
                }
            }
        }
    }

    private var gradientID: String {
        if case .gradient(let id) = item.background { return id }
        return "graphite"
    }
}
