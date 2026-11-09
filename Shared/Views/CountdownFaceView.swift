import SwiftUI
import WidgetKit

/// The widget face. Used by the widget extension and by in-app previews,
/// so what you design in the editor is exactly what lands on the desktop.
struct CountdownFaceView: View {
    let item: CountdownItem
    let size: FaceSize
    let date: Date
    @Environment(\.widgetRenderingMode) private var renderingMode

    var body: some View {
        let display = item.display(at: date)
        let palette = FacePalette(item: item, renderingMode: renderingMode)
        let context = FaceContext(item: item, display: display, palette: palette, size: size)
        Group {
            switch item.style {
            case .poster: PosterFace(c: context)
            case .minimal: MinimalFace(c: context)
            case .ring: RingFace(c: context)
            case .card: CardFace(c: context)
            }
        }
        .foregroundStyle(palette.foreground)
        .fontDesign(.rounded)
    }
}

struct FaceContext {
    let item: CountdownItem
    let display: TimeDisplay
    let palette: FacePalette
    let size: FaceSize
}

// MARK: - Shared building blocks

private struct Hero: View {
    let c: FaceContext
    let points: CGFloat
    var weight: Font.Weight = .bold
    var showUnit = true

    var body: some View {
        let d = c.display
        if d.kind == .done {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: points * 0.7, weight: .semibold))
                .widgetAccentable()
        } else if d.isUnderADay {
            LiveTimerText(display: d)
                .font(.system(size: points * 0.58, weight: weight))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .widgetAccentable()
        } else {
            HStack(alignment: .firstTextBaseline, spacing: points * 0.08) {
                Text(d.days, format: .number)
                    .font(.system(size: points, weight: weight))
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .contentTransition(.numericText())
                    .widgetAccentable()
                if showUnit {
                    Text(d.shortUnit)
                        .font(.system(size: max(9, points * 0.22), weight: .semibold))
                        .tracking(0.8)
                        .opacity(0.72)
                }
            }
        }
    }
}

/// Secondary line under the hero: the live H:MM:SS (or a caption when the hero already shows it).
private struct SubLine: View {
    let c: FaceContext
    let points: CGFloat

    var body: some View {
        let d = c.display
        Group {
            if d.kind == .done || d.isUnderADay {
                Text(d.isUnderADay ? String(localized: "left today") : d.unitLabel)
            } else {
                LiveTimerText(display: d).monospacedDigit()
            }
        }
        .font(.system(size: points, weight: .medium))
        .opacity(0.82)
        .lineLimit(1)
    }
}

private struct Title: View {
    let c: FaceContext
    let points: CGFloat
    var lines = 1

    var body: some View {
        Text(c.item.displayTitle)
            .font(.system(size: points, weight: .semibold))
            .lineLimit(lines)
    }
}

private struct RepeatBadge: View {
    let c: FaceContext
    var body: some View {
        if c.item.recurrence != nil, c.item.mode == .countdown {
            Image(systemName: "repeat")
                .font(.system(size: 11, weight: .bold))
                .opacity(0.65)
        }
    }
}

// MARK: - Poster

private struct PosterFace: View {
    let c: FaceContext

    var body: some View {
        switch c.size {
        case .small:
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .top) {
                    IconBadge(icon: c.item.icon, palette: c.palette, size: 28)
                    Spacer()
                    RepeatBadge(c: c)
                }
                Spacer(minLength: 2)
                Title(c: c, points: 13).opacity(0.92)
                Hero(c: c, points: 44)
                SubLine(c: c, points: 13)
                LiveProgressBar(display: c.display, palette: c.palette).padding(.top, 6)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)

        case .medium:
            VStack(spacing: 8) {
                HStack(alignment: .bottom, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        IconBadge(icon: c.item.icon, palette: c.palette, size: 32)
                        Spacer(minLength: 0)
                        Title(c: c, points: 17, lines: 2)
                        c.item.dateCaption(c.display).font(.system(size: 11, weight: .medium)).opacity(0.72)
                    }
                    Spacer(minLength: 0)
                    VStack(alignment: .trailing, spacing: 0) {
                        RepeatBadge(c: c)
                        Spacer(minLength: 0)
                        Hero(c: c, points: 58)
                        SubLine(c: c, points: 17)
                    }
                }
                LiveProgressBar(display: c.display, palette: c.palette)
            }

        case .large:
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 10) {
                    IconBadge(icon: c.item.icon, palette: c.palette, size: 40)
                    VStack(alignment: .leading, spacing: 1) {
                        Title(c: c, points: 18)
                        c.item.dateCaption(c.display).font(.system(size: 12, weight: .medium)).opacity(0.72)
                    }
                    Spacer(minLength: 0)
                    RepeatBadge(c: c)
                }
                Spacer(minLength: 0)
                Hero(c: c, points: 96)
                SubLine(c: c, points: 24)
                if !c.item.notes.isEmpty {
                    Text(c.item.notes).font(.system(size: 13)).opacity(0.78).lineLimit(3).padding(.top, 4)
                }
                LiveProgressBar(display: c.display, palette: c.palette).padding(.top, 4)
            }

        case .extraLarge:
            VStack(spacing: 12) {
                HStack(alignment: .bottom, spacing: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        IconBadge(icon: c.item.icon, palette: c.palette, size: 52)
                        Spacer(minLength: 0)
                        Title(c: c, points: 30, lines: 2)
                        c.item.dateCaption(c.display).font(.system(size: 15, weight: .medium)).opacity(0.75)
                        if !c.item.notes.isEmpty {
                            Text(c.item.notes).font(.system(size: 14)).opacity(0.75).lineLimit(4)
                        }
                    }
                    Spacer(minLength: 0)
                    VStack(alignment: .trailing, spacing: 0) {
                        RepeatBadge(c: c)
                        Spacer(minLength: 0)
                        Hero(c: c, points: 128)
                        SubLine(c: c, points: 32)
                    }
                }
                LiveProgressBar(display: c.display, palette: c.palette)
            }
        }
    }
}

// MARK: - Minimal

private struct MinimalFace: View {
    let c: FaceContext

    private var caps: some View {
        Text(c.item.displayTitle.uppercased())
            .font(.system(size: c.size == .small ? 10 : 12, weight: .semibold))
            .tracking(1.6)
            .opacity(0.7)
            .lineLimit(1)
    }

    var body: some View {
        switch c.size {
        case .small, .large:
            let big = c.size == .large
            VStack(spacing: big ? 6 : 2) {
                caps
                Spacer(minLength: 0)
                Hero(c: c, points: big ? 120 : 56, weight: .light, showUnit: false)
                Text(c.display.isUnderADay ? String(localized: "left today") : c.display.unitLabel)
                    .font(.system(size: big ? 15 : 11, weight: .medium))
                    .opacity(0.6)
                Spacer(minLength: 0)
                if !c.display.isUnderADay && c.display.kind != .done {
                    LiveTimerText(display: c.display)
                        .font(.system(size: big ? 22 : 14, weight: .regular))
                        .monospacedDigit()
                        .opacity(0.8)
                }
                if big {
                    c.item.dateCaption(c.display).font(.system(size: 12)).opacity(0.6)
                }
            }
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity, maxHeight: .infinity)

        case .medium, .extraLarge:
            let big = c.size == .extraLarge
            HStack(spacing: big ? 32 : 18) {
                VStack(spacing: 0) {
                    Hero(c: c, points: big ? 140 : 72, weight: .light, showUnit: false)
                    Text(c.display.isUnderADay ? String(localized: "left today") : c.display.unitLabel)
                        .font(.system(size: big ? 16 : 11, weight: .medium))
                        .opacity(0.6)
                }
                .frame(maxWidth: .infinity)
                Rectangle().fill(c.palette.foreground.opacity(0.25)).frame(width: 1).padding(.vertical, 8)
                VStack(alignment: .leading, spacing: big ? 10 : 6) {
                    caps
                    Title(c: c, points: big ? 28 : 18, lines: 2)
                    c.item.dateCaption(c.display).font(.system(size: big ? 14 : 11)).opacity(0.65)
                    if !c.display.isUnderADay && c.display.kind != .done {
                        LiveTimerText(display: c.display)
                            .font(.system(size: big ? 28 : 17, weight: .regular))
                            .monospacedDigit()
                            .opacity(0.85)
                    }
                    if big, !c.item.notes.isEmpty {
                        Text(c.item.notes).font(.system(size: 13)).opacity(0.7).lineLimit(3)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}

// MARK: - Ring

private struct RingFace: View {
    let c: FaceContext

    private var fraction: Double { c.display.kind == .down ? c.display.fraction : 1 }

    private func ring(_ diameter: CGFloat, line: CGFloat, hero: CGFloat) -> some View {
        ZStack {
            RingView(fraction: fraction, palette: c.palette, lineWidth: line)
            VStack(spacing: 0) {
                Hero(c: c, points: hero, showUnit: false)
                Text(c.display.isUnderADay ? String(localized: "left today") : c.display.shortUnit)
                    .font(.system(size: max(8, hero * 0.22), weight: .semibold))
                    .tracking(0.8)
                    .opacity(0.7)
            }
            .padding(line * 2)
        }
        .frame(width: diameter, height: diameter)
    }

    var body: some View {
        switch c.size {
        case .small:
            VStack(spacing: 6) {
                ring(100, line: 8, hero: 34)
                Title(c: c, points: 12)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

        case .medium, .extraLarge:
            let big = c.size == .extraLarge
            HStack(spacing: big ? 36 : 18) {
                ring(big ? 300 : 128, line: big ? 18 : 10, hero: big ? 96 : 42)
                VStack(alignment: .leading, spacing: big ? 10 : 5) {
                    HStack(spacing: 8) {
                        IconBadge(icon: c.item.icon, palette: c.palette, size: big ? 40 : 26)
                        RepeatBadge(c: c)
                    }
                    Title(c: c, points: big ? 30 : 17, lines: 2)
                    c.item.dateCaption(c.display).font(.system(size: big ? 15 : 11)).opacity(0.7)
                    Spacer(minLength: 0)
                    if c.display.kind != .done && !c.display.isUnderADay {
                        LiveTimerText(display: c.display)
                            .font(.system(size: big ? 34 : 20, weight: .semibold))
                            .monospacedDigit()
                    }
                    if c.display.kind == .down {
                        Text("\(Int(fraction * 100))% elapsed")
                            .font(.system(size: big ? 14 : 11, weight: .medium))
                            .opacity(0.6)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

        case .large:
            VStack(spacing: 10) {
                HStack(spacing: 10) {
                    IconBadge(icon: c.item.icon, palette: c.palette, size: 32)
                    Title(c: c, points: 17)
                    Spacer(minLength: 0)
                    RepeatBadge(c: c)
                }
                Spacer(minLength: 0)
                ring(210, line: 14, hero: 72)
                Spacer(minLength: 0)
                if c.display.kind != .done && !c.display.isUnderADay {
                    LiveTimerText(display: c.display)
                        .font(.system(size: 24, weight: .semibold))
                        .monospacedDigit()
                }
                c.item.dateCaption(c.display).font(.system(size: 12)).opacity(0.65)
            }
            .frame(maxWidth: .infinity)
        }
    }
}

// MARK: - Card (tiles)

private struct CardFace: View {
    let c: FaceContext

    private func tile<V: View>(_ label: String, scale: CGFloat, @ViewBuilder value: () -> V) -> some View {
        VStack(spacing: 2 * scale) {
            value()
                .font(.system(size: 26 * scale, weight: .bold))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.5)
            Text(label)
                .font(.system(size: max(8, 8.5 * scale), weight: .semibold))
                .tracking(1)
                .opacity(0.65)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(c.palette.foreground.opacity(c.palette.isFullColor ? 0.14 : 0.08),
                    in: RoundedRectangle(cornerRadius: 12 * scale, style: .continuous))
    }

    @ViewBuilder
    private func tiles(scale: CGFloat, vertical: Bool) -> some View {
        let d = c.display
        let layout = vertical ? AnyLayout(VStackLayout(spacing: 6 * scale)) : AnyLayout(HStackLayout(spacing: 8 * scale))
        layout {
            if d.kind == .done {
                tile(d.unitLabel.uppercased(), scale: scale) { Image(systemName: "checkmark.seal.fill").widgetAccentable() }
            } else {
                tile(d.shortUnit, scale: scale) { Text(d.days, format: .number).widgetAccentable() }
                tile(String(localized: "HRS : MIN : SEC"), scale: scale) { LiveTimerText(display: d) }
            }
        }
    }

    private var header: some View {
        HStack(spacing: 8) {
            IconBadge(icon: c.item.icon, palette: c.palette, size: c.size == .small ? 22 : 28)
            Title(c: c, points: c.size == .small ? 12 : 15)
            Spacer(minLength: 0)
            if c.size != .small {
                c.item.dateCaption(c.display).font(.system(size: 11, weight: .medium)).opacity(0.7)
            }
            RepeatBadge(c: c)
        }
    }

    var body: some View {
        switch c.size {
        case .small:
            VStack(spacing: 8) { header; tiles(scale: 0.85, vertical: true) }
        case .medium:
            VStack(spacing: 10) { header; tiles(scale: 1.15, vertical: false) }
        case .large:
            VStack(alignment: .leading, spacing: 12) {
                header
                tiles(scale: 1.6, vertical: true)
                if !c.item.notes.isEmpty {
                    Text(c.item.notes).font(.system(size: 13)).opacity(0.78).lineLimit(3)
                }
                LiveProgressBar(display: c.display, palette: c.palette)
            }
        case .extraLarge:
            VStack(alignment: .leading, spacing: 14) {
                header
                tiles(scale: 2.2, vertical: false)
                if !c.item.notes.isEmpty {
                    Text(c.item.notes).font(.system(size: 14)).opacity(0.78).lineLimit(2)
                }
                LiveProgressBar(display: c.display, palette: c.palette)
            }
        }
    }
}

// MARK: - In-app preview frame

/// Renders a face the way the desktop would: background, system margins, rounded corners.
struct WidgetPreview: View {
    let item: CountdownItem
    let size: FaceSize
    var date: Date = .now

    var body: some View {
        let frame = size.previewSize
        CountdownFaceView(item: item, size: size, date: date)
            .padding(16)
            .frame(width: frame.width, height: frame.height)
            .background { CountdownBackgroundView(item: item) }
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).strokeBorder(.white.opacity(0.08), lineWidth: 1))
            .shadow(color: .black.opacity(0.18), radius: 10, y: 5)
    }
}
