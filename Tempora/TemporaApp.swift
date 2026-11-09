import SwiftUI
import SwiftData

@main
struct TemporaApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @AppStorage("showMenuBarExtra") private var showMenuBarExtra = true
    @State private var model = AppModel.shared

    var body: some Scene {
        Window("Tempora", id: "main") {
            ContentView()
                .environment(model)
        }
        .modelContainer(SharedStore.container)
        .defaultSize(width: 1080, height: 720)
        .windowToolbarStyle(.unified)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("New Countdown…") { model.showingTemplates = true }
                    .keyboardShortcut("n")
            }
        }

        MenuBarExtra(isInserted: $showMenuBarExtra) {
            MenuBarView()
                .environment(model)
                .modelContainer(SharedStore.container)
        } label: {
            Image(nsImage: MenuBarIcon.image)
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView()
        }
    }
}
