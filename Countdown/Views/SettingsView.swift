import SwiftUI
import ServiceManagement
import UserNotifications

struct SettingsView: View {
    @AppStorage("showMenuBarExtra") private var showMenuBarExtra = true
    @State private var launchAtLogin = SMAppService.mainApp.status == .enabled
    @State private var notificationStatus: UNAuthorizationStatus = .notDetermined

    private static let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
    private static let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"

    var body: some View {
        Form {
            Section {
                HStack(spacing: 14) {
                    Image(nsImage: NSApp.applicationIconImage)
                        .resizable()
                        .frame(width: 56, height: 56)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(verbatim: "Kalan").font(.title3.weight(.semibold))
                        Text("Version \(Self.version) (\(Self.build))")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    if let url = URL(string: "https://github.com/yunusemre-cagan/Kalan") {
                        Link(destination: url) { Label("Source Code", systemImage: "chevron.left.forwardslash.chevron.right") }
                            .font(.callout)
                    }
                }
                .padding(.vertical, 4)
            }

            Section("General") {
                Toggle("Show in menu bar", isOn: $showMenuBarExtra)
                Toggle("Open at login", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { _, enabled in
                        do {
                            if enabled { try SMAppService.mainApp.register() } else { try SMAppService.mainApp.unregister() }
                        } catch {
                            launchAtLogin = SMAppService.mainApp.status == .enabled
                        }
                    }
            }

            Section("Notifications") {
                LabeledContent("Status") {
                    switch notificationStatus {
                    case .authorized, .provisional: Label("Allowed", systemImage: "checkmark.circle.fill").foregroundStyle(.green)
                    case .denied: Label("Turned off", systemImage: "xmark.circle.fill").foregroundStyle(.red)
                    default: Text("Not asked yet").foregroundStyle(.secondary)
                    }
                }
                if notificationStatus == .notDetermined {
                    Button("Allow Notifications") {
                        Task {
                            await NotificationScheduler.requestAuthorization()
                            await refreshStatus()
                            CountdownActions.refreshSideEffects()
                        }
                    }
                } else {
                    Button("Open Notification Settings…") {
                        if let url = URL(string: "x-apple.systempreferences:com.apple.Notifications-Settings.extension") {
                            NSWorkspace.shared.open(url)
                        }
                    }
                }
            }

            Section("Privacy") {
                Label("Everything stays on this Mac. Kalan has no account, no cloud sync and makes no network requests.", systemImage: "lock.shield")
                    .fixedSize(horizontal: false, vertical: true)
                LabeledContent("Database") {
                    Button("Show in Finder") {
                        NSWorkspace.shared.activateFileViewerSelecting([AppGroup.storeURL])
                    }
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 460)
        .fixedSize(horizontal: false, vertical: true)
        .task { await refreshStatus() }
    }

    private func refreshStatus() async {
        notificationStatus = await NotificationScheduler.authorizationStatus()
    }
}
