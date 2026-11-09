import SwiftUI

enum IconSpec: Codable, Hashable, Sendable {
    case none
    case symbol(String)
    case emoji(String)
    /// File name inside `AppGroup.imagesDirectory`.
    case image(String)

    var imageFile: String? { if case .image(let f) = self { f } else { nil } }
}

enum BackgroundSpec: Codable, Hashable, Sendable {
    case gradient(String)
    case solid(String)
    /// File name inside `AppGroup.imagesDirectory`, darkening (0...0.8) and blur radius.
    case image(file: String, dim: Double, blur: Double)

    var imageFile: String? { if case .image(let f, _, _) = self { f } else { nil } }

    /// Whether text on top of this background should be dark.
    var prefersDarkText: Bool {
        switch self {
        case .gradient(let id): GradientPreset.preset(id).prefersDarkText
        case .solid(let hex): Color.luminance(hex: hex) > 0.62
        case .image: false
        }
    }

    var foreground: Color { prefersDarkText ? Color(white: 0.08) : .white }
}

struct GradientPreset: Identifiable, Hashable, Sendable {
    let id: String
    let colors: [String]
    var prefersDarkText: Bool = false

    var gradient: LinearGradient {
        LinearGradient(colors: colors.map { Color(hex: $0) }, startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    static let all: [GradientPreset] = [
        .init(id: "aurora", colors: ["#0F2027", "#203A43", "#2C9F8F"]),
        .init(id: "midnight", colors: ["#0B0F2A", "#1E2A78", "#5B3FA8"]),
        .init(id: "nebula", colors: ["#2A0845", "#6441A5", "#D16BA5"]),
        .init(id: "sunset", colors: ["#FF5F6D", "#FF8E53", "#FFC371"]),
        .init(id: "ember", colors: ["#3A0A0A", "#B21F1F", "#FF7A18"]),
        .init(id: "ocean", colors: ["#0052D4", "#4364F7", "#6FB1FC"]),
        .init(id: "lagoon", colors: ["#0B486B", "#0E8C9B", "#56D5C5"]),
        .init(id: "forest", colors: ["#0B3D2E", "#1E6B4A", "#7BC67E"]),
        .init(id: "berry", colors: ["#4A0E4E", "#B5179E", "#F72585"]),
        .init(id: "rose", colors: ["#7F1D3F", "#E0446A", "#FF9A9E"]),
        .init(id: "graphite", colors: ["#141517", "#2B2D31", "#4A4D55"]),
        .init(id: "noir", colors: ["#000000", "#16181D", "#24262B"]),
        .init(id: "peach", colors: ["#FFDAB9", "#FFB199", "#FF8A80"], prefersDarkText: true),
        .init(id: "sand", colors: ["#F6EFE4", "#E9D8BC", "#D8BC8F"], prefersDarkText: true),
        .init(id: "mint", colors: ["#E6FFF5", "#B7F0D8", "#7EDCB5"], prefersDarkText: true),
        .init(id: "sky", colors: ["#E8F4FF", "#BBDDFB", "#8EC5FC"], prefersDarkText: true),
    ]

    static let `default` = all[1]

    static func preset(_ id: String) -> GradientPreset { all.first { $0.id == id } ?? .default }
}

extension Color {
    init(hex: String) {
        let (r, g, b) = Color.components(hex: hex)
        self.init(.sRGB, red: r, green: g, blue: b, opacity: 1)
    }

    static func components(hex: String) -> (Double, Double, Double) {
        var s = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if s.hasPrefix("#") { s.removeFirst() }
        guard s.count == 6, let v = UInt32(s, radix: 16) else { return (1, 1, 1) }
        return (Double((v >> 16) & 0xFF) / 255, Double((v >> 8) & 0xFF) / 255, Double(v & 0xFF) / 255)
    }

    static func luminance(hex: String) -> Double {
        let (r, g, b) = components(hex: hex)
        return 0.2126 * r + 0.7152 * g + 0.0722 * b
    }

    var hexString: String {
        let ns = NSColor(self).usingColorSpace(.sRGB) ?? .white
        return String(format: "#%02X%02X%02X",
                      Int((ns.redComponent * 255).rounded()),
                      Int((ns.greenComponent * 255).rounded()),
                      Int((ns.blueComponent * 255).rounded()))
    }
}
