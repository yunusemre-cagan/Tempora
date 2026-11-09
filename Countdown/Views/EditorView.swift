import SwiftUI
import SwiftData

struct EditorView: View {
    let request: EditorRequest
    @State private var item: CountdownItem
    @State private var previewSize: FaceSize = .medium
    @State private var confirmingDelete = false
    @FocusState private var focus: Field?
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    private enum Field { case title, notes }
    private static let titleLimit = 40
    private static let notesLimit = 200

    init(request: EditorRequest) {
        self.request = request
        _item = State(initialValue: request.item)
    }

    /// The item with its mode derived from the chosen date (see `CountdownItem.autoMode`).
    /// An existing item whose date/repeat were not touched keeps its stored mode.
    private var resolved: CountdownItem {
        var result = item
        let untouched = !request.isNew
            && item.targetDate == request.item.targetDate
            && item.recurrence == request.item.recurrence
        result.mode = untouched
            ? request.item.mode
            : CountdownItem.autoMode(date: item.targetDate, recurrence: item.recurrence)
        return result
    }

    private var canSave: Bool { !item.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

    var body: some View {
        HStack(spacing: 0) {
            form
                .frame(width: 440)
            Divider()
            preview
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) { bottomBar }
        .frame(width: 900, height: 640)
        .task {
            guard request.isNew else { return }
            try? await Task.sleep(for: .milliseconds(250))
            focus = .title
        }
    }

    // MARK: Form

    private var form: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    TextField("Name", text: $item.title, prompt: Text("Name your countdown"))
                        .labelsHidden()
                        .textFieldStyle(.plain)
                        .font(.title2.weight(.semibold))
                        .focused($focus, equals: .title)
                        .onSubmit { focus = .notes }
                        .onChange(of: item.title) { _, value in
                            if value.count > Self.titleLimit { item.title = String(value.prefix(Self.titleLimit)) }
                        }
                    Divider()
                    TextField("Description", text: $item.notes, prompt: Text("Add a note, shown on larger widgets"), axis: .vertical)
                        .labelsHidden()
                        .textFieldStyle(.plain)
                        .lineLimit(3...6)
                        .focused($focus, equals: .notes)
                        .onChange(of: item.notes) { _, value in
                            if value.count > Self.notesLimit { item.notes = String(value.prefix(Self.notesLimit)) }
                        }
                    HStack {
                        Spacer()
                        Text(verbatim: "\(item.notes.count)/\(Self.notesLimit)")
                            .font(.caption2.monospacedDigit())
                            .foregroundStyle(item.notes.count > Self.notesLimit - 20 ? Color.orange : Color.secondary.opacity(0.7))
                    }
                }
                .padding(.vertical, 4)
            }

            Section("Date") {
                LabeledContent("Date & Time") {
                    DateTimeField(date: $item.targetDate, allDay: item.isAllDay)
                }
                Toggle("All Day", isOn: $item.isAllDay)
                    .onChange(of: item.isAllDay) { _, allDay in
                        if allDay { item.targetDate = Calendar.current.startOfDay(for: item.targetDate) }
                    }
                modeHint
                if resolved.mode == .countdown && item.recurrence == nil {
                    Picker("When it ends", selection: $item.afterEnd) {
                        Text("Show as completed").tag(EndBehavior.complete)
                        Text("Keep counting up").tag(EndBehavior.countUp)
                    }
                }
            }

            Section("Appearance") {
                Picker("Style", selection: $item.style) {
                    ForEach(WidgetStyle.allCases) { Text($0.localizedName).tag($0) }
                }
                .pickerStyle(.segmented)
                IconPicker(icon: $item.icon)
                BackgroundPicker(background: $item.background)
                LabeledContent("Accent") {
                    HStack(spacing: 10) {
                        if !item.hasCustomAccent {
                            Text("Automatic").font(.callout).foregroundStyle(.secondary)
                        }
                        ColorPicker("Accent", selection: Binding(
                            get: { Color(hex: item.hasCustomAccent ? item.accentHex : item.background.foreground.hexString) },
                            set: { item.accentHex = $0.hexString }
                        ), supportsOpacity: false)
                        .labelsHidden()
                        Button("Reset") { item.accentHex = "" }
                            .disabled(!item.hasCustomAccent)
                    }
                }
            }

            RecurrenceSection(recurrence: $item.recurrence, anchor: item.targetDate)
            if resolved.mode == .countdown {
                RemindersSection(reminders: $item.reminders)
            }
        }
        .formStyle(.grouped)
    }

    /// Explains what the chosen date means, since the mode is automatic.
    private var modeHint: some View {
        let current = resolved
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        let relative = formatter.localizedString(for: item.targetDate, relativeTo: .now)
        let text: String = if item.recurrence != nil {
            String(localized: "Counting down to the next occurrence")
        } else if current.mode == .countdown {
            String(localized: "Counting down · \(relative)")
        } else {
            String(localized: "Counting up · \(relative)")
        }
        return Label {
            Text(text)
        } icon: {
            Image(systemName: current.mode == .countdown ? "hourglass" : "arrow.up.forward.circle")
        }
        .font(.callout)
        .foregroundStyle(.secondary)
    }

    // MARK: Preview

    private var preview: some View {
        VStack(spacing: 16) {
            Picker("Size", selection: $previewSize) {
                Text("Small").tag(FaceSize.small)
                Text("Medium").tag(FaceSize.medium)
                Text("Large").tag(FaceSize.large)
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .frame(width: 280)

            // The preview is scaled to always fit its pane and never takes part in hit testing,
            // so a large widget can't overlap or block the form on the left.
            GeometryReader { geometry in
                let natural = previewSize.previewSize
                let scale = min(1, max(0.1, (geometry.size.width - 12) / natural.width), max(0.1, (geometry.size.height - 12) / natural.height))
                TimelineView(BoundarySchedule(items: [resolved])) { context in
                    WidgetPreview(item: resolved, size: previewSize, date: context.date)
                        .frame(width: natural.width, height: natural.height)
                        .scaleEffect(scale)
                        .frame(width: natural.width * scale, height: natural.height * scale)
                        .animation(.smooth(duration: 0.3), value: resolved)
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
            }
            .allowsHitTesting(false)

            Label("Seconds are drawn by macOS itself, so the widget barely uses any battery.", systemImage: "leaf")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(24)
        .background {
            LinearGradient(colors: [Color(nsColor: .underPageBackgroundColor), Color(nsColor: .windowBackgroundColor)],
                           startPoint: .top, endPoint: .bottom)
        }
        .clipped()
    }

    private var bottomBar: some View {
        HStack {
            if !request.isNew {
                Button("Delete", role: .destructive) { confirmingDelete = true }
                    .confirmationDialog("Delete “\(item.displayTitle)”?", isPresented: $confirmingDelete) {
                        Button("Delete", role: .destructive) {
                            CountdownActions.delete(item.id, in: context)
                            dismiss()
                        }
                    } message: { Text("This can’t be undone.") }
            }
            Spacer()
            Button("Cancel") { dismiss() }
                .keyboardShortcut(.cancelAction)
            Button(request.isNew ? "Create" : "Save") {
                var final = resolved
                final.title = final.title.trimmingCharacters(in: .whitespacesAndNewlines)
                final.notes = final.notes.trimmingCharacters(in: .whitespacesAndNewlines)
                if final.mode == .countUp { final.recurrence = nil; final.reminders = [] }
                CountdownActions.save(final, isNew: request.isNew, in: context)
                AppModel.shared.reveal(final.id)
                dismiss()
            }
            .keyboardShortcut(.defaultAction)
            .buttonStyle(.borderedProminent)
            .disabled(!canSave)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(.bar)
    }
}

// MARK: - Date field (system calendar popover)

private struct DateTimeField: View {
    @Binding var date: Date
    let allDay: Bool
    @State private var showing = false

    var body: some View {
        Button { showing.toggle() } label: {
            HStack(spacing: 6) {
                Image(systemName: "calendar")
                Text(date, format: allDay
                     ? .dateTime.weekday(.abbreviated).day().month(.abbreviated).year()
                     : .dateTime.weekday(.abbreviated).day().month(.abbreviated).year().hour().minute())
            }
        }
        .buttonStyle(.bordered)
        .popover(isPresented: $showing, arrowEdge: .bottom) {
            // The standard macOS calendar (and clock) picker.
            DatePicker("Date & Time", selection: $date, displayedComponents: allDay ? [.date] : [.date, .hourAndMinute])
                .datePickerStyle(.graphical)
                .labelsHidden()
                .padding(16)
        }
    }
}

// MARK: - Recurrence

private struct RecurrenceSection: View {
    @Binding var recurrence: Recurrence?
    let anchor: Date

    private enum Choice: Hashable { case never, frequency(Recurrence.Frequency) }

    var body: some View {
        Section("Repeat") {
            Picker("Repeat", selection: Binding<Choice>(
                get: { recurrence.map { .frequency($0.frequency) } ?? .never },
                set: { choice in
                    switch choice {
                    case .never: recurrence = nil
                    case .frequency(let f):
                        var r = recurrence ?? Recurrence()
                        r.frequency = f
                        if f != .weekly { r.weekdays = [] }
                        recurrence = r
                    }
                }
            )) {
                Text("Never").tag(Choice.never)
                Divider()
                Text("Daily").tag(Choice.frequency(.daily))
                Text("Weekly").tag(Choice.frequency(.weekly))
                Text("Monthly").tag(Choice.frequency(.monthly))
                Text("Yearly").tag(Choice.frequency(.yearly))
            }

            if let current = recurrence {
                Stepper(value: Binding(get: { current.interval }, set: { recurrence?.interval = max(1, $0) }), in: 1...99) {
                    Text(current.localizedDescription)
                }

                if current.frequency == .weekly {
                    WeekdayPicker(selection: Binding(
                        get: { current.weekdays },
                        set: { recurrence?.weekdays = $0 }
                    ))
                }

                Toggle("End Repeat", isOn: Binding(
                    get: { current.endDate != nil },
                    set: { recurrence?.endDate = $0 ? Calendar.current.date(byAdding: .year, value: 1, to: anchor) : nil }
                ))
                if let end = current.endDate {
                    DatePicker("End Date", selection: Binding(get: { end }, set: { recurrence?.endDate = $0 }), in: anchor..., displayedComponents: .date)
                }

                if let next = current.nextOccurrence(after: .now, anchor: anchor) {
                    LabeledContent("Next") {
                        Text(next, format: .dateTime.weekday(.wide).day().month(.wide).year().hour().minute())
                    }
                    .foregroundStyle(.secondary)
                }
            }
        }
    }
}

private struct WeekdayPicker: View {
    @Binding var selection: Set<Int>

    var body: some View {
        let calendar = Calendar.current
        let symbols = calendar.veryShortStandaloneWeekdaySymbols
        let ordered = (0..<7).map { (calendar.firstWeekday - 1 + $0) % 7 + 1 }
        HStack(spacing: 6) {
            ForEach(ordered, id: \.self) { day in
                let on = selection.contains(day)
                Button {
                    if on { selection.remove(day) } else { selection.insert(day) }
                } label: {
                    Text(symbols[day - 1])
                        .font(.system(size: 12, weight: .semibold))
                        .frame(width: 30, height: 30)
                        .background(on ? Color.accentColor : Color.secondary.opacity(0.15), in: Circle())
                        .foregroundStyle(on ? .white : .primary)
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
    }
}

// MARK: - Reminders

private struct RemindersSection: View {
    @Binding var reminders: [Reminder]
    @State private var showingCustom = false
    @State private var customValue = 2
    @State private var customUnit: TimeInterval = 3600

    var body: some View {
        Section("Notifications") {
            ForEach(reminders.sorted { $0.offset > $1.offset }) { reminder in
                HStack {
                    Image(systemName: "bell.fill").foregroundStyle(.tint)
                    Text(reminder.localizedDescription)
                    Spacer()
                    Button {
                        reminders.removeAll { $0.id == reminder.id }
                    } label: {
                        Image(systemName: "minus.circle.fill").foregroundStyle(.secondary)
                    }
                    .buttonStyle(.borderless)
                }
            }
            Menu {
                ForEach(Reminder.presets.filter { offset in !reminders.contains { $0.offset == offset } }, id: \.self) { offset in
                    Button(Reminder(offset: offset).localizedDescription) { reminders.append(Reminder(offset: offset)) }
                }
                Divider()
                Button("Custom…") { showingCustom = true }
            } label: {
                Label("Add Notification", systemImage: "plus")
            }
            .menuStyle(.borderlessButton)
            .fixedSize()
            .popover(isPresented: $showingCustom, arrowEdge: .bottom) {
                HStack {
                    Stepper(value: $customValue, in: 1...999) {
                        TextField("", value: $customValue, format: .number).frame(width: 50)
                    }
                    Picker("", selection: $customUnit) {
                        Text("minutes").tag(TimeInterval(60))
                        Text("hours").tag(TimeInterval(3600))
                        Text("days").tag(TimeInterval(86_400))
                        Text("weeks").tag(TimeInterval(604_800))
                    }
                    .labelsHidden()
                    .fixedSize()
                    Text("before")
                    Button("Add") {
                        let offset = TimeInterval(customValue) * customUnit
                        if !reminders.contains(where: { $0.offset == offset }) { reminders.append(Reminder(offset: offset)) }
                        showingCustom = false
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding(14)
            }
        }
    }
}
