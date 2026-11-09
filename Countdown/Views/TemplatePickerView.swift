import SwiftUI

struct TemplatePickerView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("New Countdown").font(.title2.bold())
                    Text("Start from a template or a blank countdown.").foregroundStyle(.secondary)
                }
                Spacer()
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)
            }
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 14)], spacing: 14) {
                    ForEach(CountdownTemplate.all) { template in
                        TemplateTile(template: template) { model.create(from: template) }
                    }
                }
                .padding(2)
            }
        }
        .padding(24)
        .frame(width: 720, height: 600)
    }
}

private struct TemplateTile: View {
    let template: CountdownTemplate
    let action: () -> Void
    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 0) {
                Image(systemName: template.symbol)
                    .font(.system(size: 22, weight: .semibold))
                    .frame(width: 42, height: 42)
                    .background(.white.opacity(0.18), in: Circle())
                Spacer()
                Text(template.title).font(.system(size: 15, weight: .semibold, design: .rounded))
                Text(subtitle).font(.system(size: 11, weight: .medium, design: .rounded)).opacity(0.75)
            }
            .foregroundStyle(GradientPreset.preset(template.gradient).prefersDarkText ? Color(white: 0.1) : .white)
            .padding(14)
            .frame(maxWidth: .infinity, minHeight: 130, alignment: .leading)
            .background(GradientPreset.preset(template.gradient).gradient, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .scaleEffect(hovering ? 1.03 : 1)
            .shadow(color: .black.opacity(hovering ? 0.2 : 0.08), radius: hovering ? 10 : 4, y: 3)
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
        .animation(.spring(duration: 0.25), value: hovering)
    }

    private var subtitle: String {
        if template.mode == .countUp { return String(localized: "Count up") }
        if let recurrence = template.recurrence { return recurrence.localizedDescription }
        return template.id == "blank" ? String(localized: "Start from scratch") : String(localized: "One time")
    }
}
