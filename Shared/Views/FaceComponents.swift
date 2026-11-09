import SwiftUI
import WidgetKit

enum FaceSize: String, CaseIterable, Identifiable, Sendable {
    case small, medium, large, extraLarge
    var id: String { rawValue }

    /// Approximate macOS widget sizes, used for in-app previews.
    var previewSize: CGSize {
        switch self {
        case .small: CGSize(width: 170, height: 170)
        case .medium: CGSize(width: 364, height: 170)
        case .large: CGSize(width: 364, height: 382)
        case .extraLarge: CGSize(width: 768, height: 382)
        }
    }

    init(_ family: WidgetFamily) {
        switch family {
        case .systemMedium: self = .medium
        case .systemLarge: self = .large
        case .systemExtraLarge: self = .extraLarge
        default: self = .small
        }
    }
}

/// Colors resolved for the current widget rendering mode.
struct FacePalette {
    let foreground: Color
    let accent: Color
    let isFullColor: Bool

    init(item: CountdownItem, renderingMode: WidgetRenderingMode) {
        isFullColor = renderingMode == .fullColor
        // The accent always colors bars and rings; it only tints text when the user turns that on.
        let base = item.background.foreground
        let custom: Color? = item.hasCustomAccent ? Color(hex: item.accentHex) : nil
        foreground = isFullColor ? (item.accentOnText ? (custom ?? base) : base) : .primary
        accent = isFullColor ? (custom ?? base) : .primary
    }
}

// MARK: - Background

struct CountdownBackgroundView: View {
    let item: CountdownItem

    var body: some View {
        ZStack {
            switch item.background {
            case .gradient(let id):
                GradientPreset.preset(id).gradient
                GlowOverlay()
            case .solid(let hex):
                Color(hex: hex)
                GlowOverlay()
            case .image(let file, let dim, let blur):
                if let image = ImageStore.image(named: file) {
                    Color.black
                    Image(nsImage: image)
                        .resizable()
                        .widgetAccentedRenderingMode(.desaturated)
                        .scaledToFill()
                        .blur(radius: blur, opaque: true)
                    Color.black.opacity(dim)
                    LinearGradient(colors: [.black.opacity(0), .black.opacity(0.55)], startPoint: .center, endPoint: .bottom)
                } else {
                    GradientPreset.default.gradient
                }
            }
        }
    }
}

/// Soft light bloom in the top-left corner that gives flat fills some depth.
private struct GlowOverlay: View {
    var body: some View {
        RadialGradient(colors: [.white.opacity(0.22), .clear], center: .topLeading, startRadius: 0, endRadius: 260)
            .blendMode(.softLight)
    }
}

// MARK: - Pieces

struct IconBadge: View {
    let icon: IconSpec
    let palette: FacePalette
    var size: CGFloat = 28

    var body: some View {
        switch icon {
        case .none:
            EmptyView()
        case .symbol(let name):
            Image(systemName: name)
                .font(.system(size: size * 0.5, weight: .semibold))
                .foregroundStyle(palette.foreground)
                .frame(width: size, height: size)
                .background(palette.foreground.opacity(0.16), in: Circle())
                .widgetAccentable()
        case .emoji(let emoji):
            Text(emoji)
                .font(.system(size: size * 0.62))
                .frame(width: size, height: size)
                .background(palette.foreground.opacity(0.16), in: Circle())
        case .image(let file):
            if let image = ImageStore.image(named: file) {
                Image(nsImage: image)
                    .resizable()
                    .widgetAccentedRenderingMode(.fullColor)
                    .scaledToFill()
                    .frame(width: size, height: size)
                    .clipShape(Circle())
                    .overlay(Circle().strokeBorder(palette.foreground.opacity(0.35), lineWidth: 1))
            }
        }
    }
}

/// Sub-day part, driven by the system clock (no app wake-ups).
struct LiveTimerText: View {
    let display: TimeDisplay

    var body: some View {
        switch display.kind {
        case .down:
            Text(timerInterval: display.timerRange, countsDown: true, showsHours: true)
        case .up:
            Text(timerInterval: display.timerRange, countsDown: false, showsHours: true)
        case .done:
            Text(display.reference, format: .dateTime.day().month(.abbreviated).year())
        }
    }
}

struct LiveProgressBar: View {
    let display: TimeDisplay
    let palette: FacePalette
    var height: CGFloat = 4

    var body: some View {
        if let range = display.progressRange, display.kind == .down {
            ProgressView(timerInterval: range, countsDown: false) { EmptyView() } currentValueLabel: { EmptyView() }
                .progressViewStyle(.linear)
                .labelsHidden()
                .tint(palette.accent)
                .widgetAccentable()
        }
    }
}

struct RingView: View {
    let fraction: Double
    let palette: FacePalette
    var lineWidth: CGFloat = 7

    var body: some View {
        ZStack {
            Circle().stroke(palette.foreground.opacity(0.18), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: max(0.001, fraction))
                .stroke(palette.accent, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .widgetAccentable()
        }
    }
}

extension TimeDisplay {
    var unitLabel: String {
        switch kind {
        case .down: days == 1 ? String(localized: "day left") : String(localized: "days left")
        case .up: days == 1 ? String(localized: "day") : String(localized: "days")
        case .done: String(localized: "Completed")
        }
    }

    var shortUnit: String {
        days == 1 ? String(localized: "DAY") : String(localized: "DAYS")
    }
}

extension CountdownItem {
    func dateCaption(_ display: TimeDisplay) -> Text {
        let date = display.reference
        let formatted = isAllDay
            ? date.formatted(.dateTime.day().month(.abbreviated).year())
            : date.formatted(.dateTime.day().month(.abbreviated).year().hour().minute())
        switch display.kind {
        case .up: return Text("Since \(formatted)")
        case .done: return Text("Ended \(formatted)")
        case .down: return Text(formatted)
        }
    }
}

extension FacePalette {
    init(foreground: Color, accent: Color, isFullColor: Bool) {
        self.foreground = foreground
        self.accent = accent
        self.isFullColor = isFullColor
    }
}

extension Array where Element == CountdownItem {
    func sortedForDisplay(at now: Date = .now) -> [CountdownItem] {
        sorted { lhs, rhs in
            let l = lhs.sortKey(at: now), r = rhs.sortKey(at: now)
            return l.0 != r.0 ? l.0 < r.0 : l.1 < r.1
        }
    }
}

extension CountdownItem {
    static var sample: CountdownItem {
        CountdownItem(
            title: String(localized: "Summer Vacation"),
            notes: String(localized: "Pack light, bring sunscreen."),
            targetDate: Date().addingTimeInterval(12 * 86_400 + 5 * 3600 + 23 * 60),
            icon: .symbol("sun.max.fill"),
            background: .gradient("sunset"),
            createdAt: Date().addingTimeInterval(-20 * 86_400)
        )
    }
}
