import Foundation

/// Location of everything the app persists. All data lives on this Mac,
/// inside the App Group container shared by the app and its widget.
enum AppGroup {
    static let identifier = "L3VTRSDZZZ.com.yunusemrecagan.Countdown"

    static var containerURL: URL {
        if let url = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: identifier) {
            return url
        }
        // Fallback (e.g. unsigned builds): the process' own Application Support.
        return URL.applicationSupportDirectory.appending(path: "Countdown", directoryHint: .isDirectory)
    }

    static var storeDirectory: URL { directory("Library/Application Support/Countdown") }
    static var storeURL: URL { storeDirectory.appending(path: "Countdown.store") }
    static var imagesDirectory: URL { directory("Library/Application Support/Countdown/Images") }

    private static func directory(_ relative: String) -> URL {
        let url = containerURL.appending(path: relative, directoryHint: .isDirectory)
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }
}
