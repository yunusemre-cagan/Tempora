import SwiftUI
import UniformTypeIdentifiers

struct IconPicker: View {
    @Binding var icon: IconSpec
    @State private var showing = false

    var body: some View {
        LabeledContent("Icon") {
            Button { showing.toggle() } label: {
                HStack(spacing: 8) {
                    IconBadge(icon: icon, palette: FacePalette(foreground: .primary, accent: .primary, isFullColor: true), size: 24)
                    if case .none = icon { Text("None").foregroundStyle(.secondary) }
                    Image(systemName: "chevron.down").font(.caption2.bold()).foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.bordered)
            .popover(isPresented: $showing, arrowEdge: .trailing) {
                IconPickerPopover(icon: $icon)
            }
        }
    }
}

private struct IconPickerPopover: View {
    @Binding var icon: IconSpec
    @State private var tab = 0
    @State private var search = ""
    @State private var emoji = ""
    @State private var importing = false
    @State private var importError: String?

    static let symbols = [
        "hourglass", "timer", "clock.fill", "alarm.fill", "calendar", "star.fill", "sparkles", "heart.fill",
        "birthday.cake.fill", "gift.fill", "party.popper.fill", "balloon.2.fill", "airplane", "car.fill", "tram.fill", "sailboat.fill",
        "beach.umbrella.fill", "sun.max.fill", "moon.stars.fill", "snowflake", "leaf.fill", "tree.fill", "mountain.2.fill", "flame.fill",
        "graduationcap.fill", "book.fill", "pencil", "briefcase.fill", "laptopcomputer", "flag.checkered", "trophy.fill", "medal.fill",
        "paperplane.fill", "bolt.fill", "music.note", "guitars.fill", "film.fill", "gamecontroller.fill", "sportscourt.fill", "figure.run",
        "dumbbell.fill", "soccerball", "basketball.fill", "tennis.racket", "bicycle", "cup.and.saucer.fill", "fork.knife", "wineglass.fill",
        "house.fill", "building.2.fill", "cart.fill", "creditcard.fill", "dollarsign.circle.fill", "banknote.fill", "stethoscope", "pills.fill",
        "cross.case.fill", "pawprint.fill", "figure.2.and.child.holdinghands", "person.2.fill", "ring.circle.fill", "camera.fill", "paintpalette.fill",
        "globe.europe.africa.fill", "map.fill", "tent.fill", "binoculars.fill", "crown.fill", "bell.fill", "lightbulb.fill", "checkmark.seal.fill",
    ]
    static let emojis = ["🎉", "🎂", "🎄", "🎆", "✈️", "🏖️", "🏔️", "🎓", "📚", "💼", "🚀", "💍", "❤️", "👶", "🐶", "⚽️", "🎸", "🎬", "🏆", "🌙", "☀️", "🌸", "🍀", "🔥"]

    var body: some View {
        VStack(spacing: 12) {
            Picker("", selection: $tab) {
                Text("Symbols").tag(0)
                Text("Emoji").tag(1)
                Text("Image").tag(2)
            }
            .pickerStyle(.segmented)
            .labelsHidden()

            switch tab {
            case 0: symbolGrid
            case 1: emojiGrid
            default: imageTab
            }

            HStack {
                Button("No Icon") { icon = .none }
                Spacer()
            }
            .buttonStyle(.borderless)
            .font(.callout)
        }
        .padding(14)
        .frame(width: 360, height: 360)
        .onAppear {
            switch icon {
            case .emoji: tab = 1
            case .image: tab = 2
            default: tab = 0
            }
        }
    }

    private var symbolGrid: some View {
        VStack {
            TextField("Search symbols", text: $search)
                .textFieldStyle(.roundedBorder)
            ScrollView {
                let list = search.isEmpty ? Self.symbols : Self.symbols.filter { $0.localizedCaseInsensitiveContains(search) }
                LazyVGrid(columns: Array(repeating: GridItem(.fixed(36), spacing: 6), count: 8), spacing: 6) {
                    ForEach(list, id: \.self) { name in
                        let selected = icon == .symbol(name)
                        Button { icon = .symbol(name) } label: {
                            Image(systemName: name)
                                .font(.system(size: 16, weight: .medium))
                                .frame(width: 36, height: 36)
                                .background(selected ? Color.accentColor.opacity(0.25) : Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
                        }
                        .buttonStyle(.plain)
                        .help(name)
                    }
                }
            }
        }
    }

    private var emojiGrid: some View {
        VStack {
            HStack {
                TextField("Type any emoji", text: $emoji)
                    .textFieldStyle(.roundedBorder)
                    .onChange(of: emoji) { _, value in
                        if let first = value.first { icon = .emoji(String(first)); emoji = String(first) }
                    }
                Button("Emoji Picker") { NSApp.orderFrontCharacterPalette(nil) }
            }
            LazyVGrid(columns: Array(repeating: GridItem(.fixed(36), spacing: 6), count: 8), spacing: 6) {
                ForEach(Self.emojis, id: \.self) { e in
                    Button { icon = .emoji(e) } label: {
                        Text(e).font(.system(size: 22))
                            .frame(width: 36, height: 36)
                            .background(icon == .emoji(e) ? Color.accentColor.opacity(0.25) : Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                }
            }
            Spacer()
        }
    }

    private var imageTab: some View {
        VStack(spacing: 12) {
            Spacer()
            if let file = icon.imageFile, let image = ImageStore.image(named: file) {
                Image(nsImage: image).resizable().scaledToFill().frame(width: 96, height: 96).clipShape(Circle())
            } else {
                Image(systemName: "photo.circle").font(.system(size: 64)).foregroundStyle(.tertiary)
            }
            Button("Choose Image…") { importing = true }
            Text("Or drop an image here").font(.caption).foregroundStyle(.secondary)
            if let importError { Text(importError).font(.caption).foregroundStyle(.red) }
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .dropDestination(for: URL.self) { urls, _ in
            guard let url = urls.first else { return false }
            load(url)
            return true
        }
        .fileImporter(isPresented: $importing, allowedContentTypes: [.image]) { result in
            if case .success(let url) = result { load(url) }
        }
    }

    private func load(_ url: URL) {
        do { icon = .image(try ImageStore.importImage(from: url, kind: .icon)); importError = nil }
        catch { importError = String(localized: "Couldn’t read that image.") }
    }
}
