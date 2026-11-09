import SwiftUI
import WidgetKit

struct TemporaEntry: TimelineEntry {
    let date: Date
    let item: CountdownItem?
}

/// Timeline = one entry per day boundary. Seconds are animated by the system
/// via `Text(timerInterval:)`, so the extension only runs a few times per day.
struct TemporaProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> TemporaEntry {
        TemporaEntry(date: .now, item: .sample)
    }

    func snapshot(for configuration: SelectCountdownIntent, in context: Context) async -> TemporaEntry {
        TemporaEntry(date: .now, item: resolve(configuration) ?? .sample)
    }

    func timeline(for configuration: SelectCountdownIntent, in context: Context) async -> Timeline<TemporaEntry> {
        let now = Date()
        guard let item = resolve(configuration) else {
            return Timeline(entries: [TemporaEntry(date: now, item: nil)], policy: .never)
        }
        let dates = [now] + item.boundaries(after: now)
        let entries = dates.map { TemporaEntry(date: $0, item: item) }
        let policy: TimelineReloadPolicy = dates.count > 1 ? .atEnd : .never
        return Timeline(entries: entries, policy: policy)
    }

    private func resolve(_ configuration: SelectCountdownIntent) -> CountdownItem? {
        if let id = configuration.countdown?.id, let item = SharedStore.fetchItem(id: id) {
            return item
        }
        return SharedStore.fetchItems().sortedForDisplay().first
    }
}

struct TemporaWidget: Widget {
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: "TemporaWidget", intent: SelectCountdownIntent.self, provider: TemporaProvider()) { entry in
            TemporaWidgetView(entry: entry)
        }
        .configurationDisplayName("Tempora")
        .description("A single countdown, down to the second.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge, .systemExtraLarge])
    }
}

struct TemporaWidgetView: View {
    let entry: TemporaEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        if let item = entry.item {
            CountdownFaceView(item: item, size: FaceSize(family), date: entry.date)
                .containerBackground(for: .widget) { CountdownBackgroundView(item: item) }
                .widgetURL(URL(string: "tempora://open/\(item.id.uuidString)"))
        } else {
            EmptyWidgetView()
                .containerBackground(for: .widget) { GradientPreset.default.gradient }
        }
    }
}

struct EmptyWidgetView: View {
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "hourglass")
                .font(.system(size: 26, weight: .semibold))
            Text("Create a countdown in the app")
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .multilineTextAlignment(.center)
                .opacity(0.8)
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
