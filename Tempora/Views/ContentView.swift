import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.modelContext) private var context
    @Query private var countdowns: [Countdown]

    var body: some View {
        @Bindable var model = model
        let items = countdowns.map(\.item)

        NavigationSplitView {
            List(selection: $model.filter) {
                Section("Library") {
                    ForEach(SidebarFilter.allCases) { filter in
                        Label(filter.title, systemImage: filter.symbol)
                            .badge(items.filter { filter.matches($0) }.count)
                            .tag(filter)
                    }
                }
            }
            .navigationSplitViewColumnWidth(min: 190, ideal: 210)
        } detail: {
            CountdownGridView(items: items.filter { model.filter.matches($0) }.sortedForDisplay(), isEmptyLibrary: items.isEmpty)
                .navigationTitle(Text(model.filter.title))
        }
        .frame(minWidth: 780, minHeight: 500)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    model.showingTemplates = true
                } label: {
                    Label("New Countdown", systemImage: "plus")
                }
                .help("New Countdown")
            }
        }
        .sheet(isPresented: $model.showingTemplates) {
            TemplatePickerView()
        }
        .sheet(item: $model.editing) { request in
            EditorView(request: request)
        }
        .onOpenURL { url in
            guard url.scheme == "tempora", let id = UUID(uuidString: url.lastPathComponent) else { return }
            model.reveal(id)
        }
    }
}
