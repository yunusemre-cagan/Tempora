import SwiftUI
import UniformTypeIdentifiers

struct BackgroundPicker: View {
    @Binding var background: BackgroundSpec
    @State private var kind: Kind = .gradient
    @State private var importing = false
    @State private var importError: String?

    enum Kind: Hashable { case gradient, color, image }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Picker("Background", selection: $kind) {
                Text("Gradient").tag(Kind.gradient)
                Text("Color").tag(Kind.color)
                Text("Image").tag(Kind.image)
            }
            .onChange(of: kind) { _, newKind in apply(newKind) }

            switch kind {
            case .gradient:
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 8), spacing: 8) {
                    ForEach(GradientPreset.all) { preset in
                        let selected = background == .gradient(preset.id)
                        Button { background = .gradient(preset.id) } label: {
                            RoundedRectangle(cornerRadius: 9, style: .continuous)
                                .fill(preset.gradient)
                                .aspectRatio(1, contentMode: .fit)
                                .overlay {
                                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                                        .strokeBorder(selected ? Color.accentColor : .primary.opacity(0.1), lineWidth: selected ? 3 : 1)
                                }
                        }
                        .buttonStyle(.plain)
                        .help(preset.id.capitalized)
                    }
                }
            case .color:
                ColorPicker("Color", selection: Binding(
                    get: { if case .solid(let hex) = background { Color(hex: hex) } else { Color(hex: "#1E2A78") } },
                    set: { background = .solid($0.hexString) }
                ), supportsOpacity: false)
            case .image:
                imageControls
            }
        }
        .onAppear {
            switch background {
            case .gradient: kind = .gradient
            case .solid: kind = .color
            case .image: kind = .image
            }
        }
        .fileImporter(isPresented: $importing, allowedContentTypes: [.image]) { result in
            if case .success(let url) = result { load(url) }
        }
    }

    @ViewBuilder
    private var imageControls: some View {
        HStack(spacing: 12) {
            ZStack {
                if let file = background.imageFile, let image = ImageStore.image(named: file) {
                    Image(nsImage: image).resizable().scaledToFill()
                } else {
                    Rectangle().fill(.quaternary)
                    Image(systemName: "photo.on.rectangle.angled").font(.title2).foregroundStyle(.secondary)
                }
            }
            .frame(width: 110, height: 70)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .dropDestination(for: URL.self) { urls, _ in
                guard let url = urls.first else { return false }
                load(url)
                return true
            }
            VStack(alignment: .leading, spacing: 4) {
                Button("Choose Image…") { importing = true }
                Text("or drop one on the thumbnail").font(.caption).foregroundStyle(.secondary)
                if let importError { Text(importError).font(.caption).foregroundStyle(.red) }
            }
        }
        if case .image(let file, let dim, let blur) = background {
            LabeledContent("Darken") {
                Slider(value: Binding(get: { dim }, set: { background = .image(file: file, dim: $0, blur: blur) }), in: 0...0.8)
            }
            LabeledContent("Blur") {
                Slider(value: Binding(get: { blur }, set: { background = .image(file: file, dim: dim, blur: $0) }), in: 0...20)
            }
        }
    }

    private func apply(_ kind: Kind) {
        switch (kind, background) {
        case (.gradient, .gradient), (.color, .solid), (.image, .image): return
        case (.gradient, _): background = .gradient(GradientPreset.default.id)
        case (.color, _): background = .solid("#1E2A78")
        case (.image, _): importing = true
        }
    }

    private func load(_ url: URL) {
        do {
            let file = try ImageStore.importImage(from: url, kind: .background)
            background = .image(file: file, dim: 0.2, blur: 0)
            importError = nil
        } catch {
            importError = String(localized: "Couldn’t read that image.")
        }
    }
}
