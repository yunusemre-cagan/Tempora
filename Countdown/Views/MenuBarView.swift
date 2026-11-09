import SwiftUI
import SwiftData

struct MenuBarView: View {
    @Query private var countdowns: [Countdown]
    @Environment(AppModel.self) private var model
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        let items = Array(countdowns.map(\.item).filter { !$0.isArchived && !$0.isFinished }.sortedForDisplay().prefix(5))
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(verbatim: "Tempora").font(.headline)
                Spacer()
                Button {
                    open()
                    model.showingTemplates = true
                } label: { Image(systemName: "plus") }
                .buttonStyle(.borderless)
                .help("New Countdown")
            }

            if items.isEmpty {
                Text("No upcoming countdowns")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 60)
            } else {
                TimelineView(BoundarySchedule(items: items)) { context in
                    VStack(spacing: 6) {
                        ForEach(items) { item in
                            Button {
                                open()
                                model.reveal(item.id)
                            } label: {
                                MenuRow(item: item, date: context.date)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }

            Divider()
            HStack {
                Button("Open Tempora") { open() }
                Spacer()
                SettingsLink { Image(systemName: "gearshape") }
                    .help("Settings")
                Button { NSApp.terminate(nil) } label: { Image(systemName: "power") }
                    .help("Quit")
            }
            .buttonStyle(.borderless)
        }
        .padding(14)
        .frame(width: 320)
    }

    private func open() {
        openWindow(id: "main")
        NSApp.activate()
    }
}

private struct MenuRow: View {
    let item: CountdownItem
    let date: Date

    var body: some View {
        let display = item.display(at: date)
        let palette = FacePalette(item: item, renderingMode: .fullColor)
        HStack(spacing: 10) {
            IconBadge(icon: item.icon, palette: palette, size: 28)
            VStack(alignment: .leading, spacing: 1) {
                Text(item.displayTitle).font(.system(size: 13, weight: .semibold)).lineLimit(1)
                item.dateCaption(display).font(.system(size: 10)).opacity(0.75).lineLimit(1)
            }
            Spacer(minLength: 6)
            VStack(alignment: .trailing, spacing: 0) {
                if display.isUnderADay {
                    LiveTimerText(display: display).font(.system(size: 15, weight: .bold)).monospacedDigit()
                } else {
                    Text("\(display.days) \(display.shortUnit)").font(.system(size: 15, weight: .bold))
                    LiveTimerText(display: display).font(.system(size: 10, weight: .medium)).monospacedDigit().opacity(0.75)
                }
            }
        }
        .fontDesign(.rounded)
        .foregroundStyle(palette.foreground)
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background { CountdownBackgroundView(item: item) }
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .contentShape(Rectangle())
    }
}
