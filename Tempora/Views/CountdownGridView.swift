import SwiftUI
import SwiftData

struct CountdownGridView: View {
    let items: [CountdownItem]
    let isEmptyLibrary: Bool
    @Environment(AppModel.self) private var model
    @AppStorage("dismissedDesktopTip") private var dismissedDesktopTip = false

    var body: some View {
        if items.isEmpty {
            emptyState
        } else {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        if !dismissedDesktopTip { DesktopTip { dismissedDesktopTip = true } }
                        // Only re-render when a day boundary passes; seconds tick in-place.
                        TimelineView(BoundarySchedule(items: items)) { context in
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 364, maximum: 364), spacing: 22)], alignment: .leading, spacing: 22) {
                                ForEach(items) { item in
                                    CountdownCard(item: item, date: context.date, isHighlighted: model.highlightedID == item.id)
                                        .id(item.id)
                                }
                            }
                        }
                    }
                    .padding(28)
                }
                .onChange(of: model.highlightedID) { _, id in
                    guard let id else { return }
                    withAnimation { proxy.scrollTo(id, anchor: .center) }
                    Task {
                        try? await Task.sleep(for: .seconds(2))
                        if model.highlightedID == id { model.highlightedID = nil }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var emptyState: some View {
        if isEmptyLibrary {
            ContentUnavailableView {
                Label("No Countdowns Yet", systemImage: "hourglass")
            } description: {
                Text("Create your first countdown, then add it to your desktop as a widget.")
            } actions: {
                Button("New Countdown") { model.showingTemplates = true }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
            }
        } else {
            ContentUnavailableView("Nothing Here", systemImage: model.filter.symbol)
        }
    }
}

private struct CountdownCard: View {
    let item: CountdownItem
    let date: Date
    let isHighlighted: Bool
    @Environment(AppModel.self) private var model
    @Environment(\.modelContext) private var context
    @State private var hovering = false
    @State private var confirmingDelete = false

    var body: some View {
        WidgetPreview(item: item, size: .medium, date: date)
            .overlay(alignment: .topTrailing) {
                if hovering {
                    Button { model.edit(item) } label: {
                        Image(systemName: "pencil").font(.system(size: 12, weight: .bold)).frame(width: 26, height: 26)
                    }
                    .buttonStyle(.glass)
                    .buttonBorderShape(.circle)
                    .padding(10)
                    .transition(.opacity.combined(with: .scale(scale: 0.8)))
                }
            }
            .overlay {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .strokeBorder(Color.accentColor, lineWidth: 3)
                    .opacity(isHighlighted ? 1 : 0)
            }
            .scaleEffect(hovering ? 1.015 : 1)
            .animation(.spring(duration: 0.25), value: hovering)
            .onHover { hovering = $0 }
            .onTapGesture(count: 2) { model.edit(item) }
            .contextMenu {
                Button("Edit…", systemImage: "pencil") { model.edit(item) }
                Button("Duplicate", systemImage: "plus.square.on.square") { CountdownActions.duplicate(item, in: context) }
                if item.isArchived {
                    Button("Unarchive", systemImage: "tray.and.arrow.up") { CountdownActions.setArchived(false, id: item.id, in: context) }
                } else {
                    Button("Archive", systemImage: "archivebox") { CountdownActions.setArchived(true, id: item.id, in: context) }
                }
                Divider()
                Button("Delete…", systemImage: "trash", role: .destructive) { confirmingDelete = true }
            }
            .confirmationDialog("Delete “\(item.displayTitle)”?", isPresented: $confirmingDelete) {
                Button("Delete", role: .destructive) { CountdownActions.delete(item.id, in: context) }
            } message: {
                Text("This can’t be undone.")
            }
    }
}

private struct DesktopTip: View {
    let dismiss: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "macwindow.on.rectangle")
                .font(.title2)
                .foregroundStyle(.tint)
            VStack(alignment: .leading, spacing: 2) {
                Text("Put a countdown on your desktop").font(.headline)
                Text("Right-click the desktop, choose “Edit Widgets…”, search for Tempora and drag one out. Right-click a placed widget → “Edit” to pick which countdown it shows.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
            Button(action: dismiss) { Image(systemName: "xmark") }
                .buttonStyle(.borderless)
                .help("Dismiss")
        }
        .padding(16)
        .glassEffect(in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

/// Fires only at the instants where some visible card's day count changes.
struct BoundarySchedule: TimelineSchedule {
    let items: [CountdownItem]

    func entries(from startDate: Date, mode: TimelineScheduleMode) -> [Date] {
        let boundaries = Set(items.flatMap { $0.boundaries(after: startDate, limit: 4) })
        return [startDate] + boundaries.sorted().prefix(64)
    }
}
