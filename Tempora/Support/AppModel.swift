import SwiftUI
import SwiftData
import WidgetKit

enum SidebarFilter: String, CaseIterable, Identifiable {
    case upcoming, countUp, completed, archived
    var id: String { rawValue }

    var title: LocalizedStringKey {
        switch self {
        case .upcoming: "Upcoming"
        case .countUp: "Count Ups"
        case .completed: "Completed"
        case .archived: "Archived"
        }
    }

    var symbol: String {
        switch self {
        case .upcoming: "hourglass"
        case .countUp: "arrow.up.forward.circle"
        case .completed: "checkmark.seal"
        case .archived: "archivebox"
        }
    }

    func matches(_ item: CountdownItem, now: Date = .now) -> Bool {
        if self == .archived { return item.isArchived }
        if item.isArchived { return false }
        switch item.phase(at: now) {
        case .counting: return self == .upcoming
        case .countingUp: return self == .countUp
        case .finished: return self == .completed
        }
    }
}

struct EditorRequest: Identifiable {
    let id = UUID()
    var item: CountdownItem
    let isNew: Bool
}

@MainActor @Observable
final class AppModel {
    static let shared = AppModel()

    var filter: SidebarFilter = .upcoming
    var editing: EditorRequest?
    var showingTemplates = false
    var highlightedID: UUID?

    func create(from template: CountdownTemplate) {
        showingTemplates = false
        var item = template.makeItem()
        item.sortOrder = Int(Date().timeIntervalSince1970)
        editing = EditorRequest(item: item, isNew: true)
    }

    func edit(_ item: CountdownItem) {
        editing = EditorRequest(item: item, isNew: false)
    }

    func reveal(_ id: UUID) {
        if let item = SharedStore.fetchItem(id: id) {
            filter = SidebarFilter.allCases.first { $0.matches(item) } ?? .upcoming
        }
        highlightedID = id
    }
}

/// All mutations go through here so the widget and notifications stay in sync.
@MainActor
enum CountdownActions {
    static func save(_ item: CountdownItem, isNew: Bool, in context: ModelContext) {
        if !isNew, let existing = model(id: item.id, in: context) {
            existing.apply(item)
        } else {
            context.insert(Countdown(item: item))
        }
        commit(context)
    }

    static func delete(_ id: UUID, in context: ModelContext) {
        guard let existing = model(id: id, in: context) else { return }
        let files = [existing.item.icon.imageFile, existing.item.background.imageFile].compactMap { $0 }
        context.delete(existing)
        commit(context)
        for file in files { try? FileManager.default.removeItem(at: AppGroup.imagesDirectory.appending(path: file)) }
    }

    static func setArchived(_ archived: Bool, id: UUID, in context: ModelContext) {
        guard let existing = model(id: id, in: context) else { return }
        existing.isArchived = archived
        commit(context)
    }

    static func duplicate(_ item: CountdownItem, in context: ModelContext) {
        var copy = item
        copy.id = UUID()
        copy.createdAt = .now
        copy.title = String(localized: "\(item.displayTitle) Copy")
        copy.isArchived = false
        // Images are files: give the copy its own so deleting one doesn't break the other.
        copy.icon = duplicateFile(copy.icon)
        if case .image(let file, let dim, let blur) = copy.background, let newFile = copyImage(file) {
            copy.background = .image(file: newFile, dim: dim, blur: blur)
        }
        context.insert(Countdown(item: copy))
        commit(context)
    }

    static func refreshSideEffects() {
        WidgetCenter.shared.reloadAllTimelines()
        let items = SharedStore.fetchItems()
        Task { await NotificationScheduler.reschedule(items) }
    }

    static func cleanUpImages() {
        let items = SharedStore.fetchItems(includeArchived: true)
        let used = Set(items.flatMap { [$0.icon.imageFile, $0.background.imageFile].compactMap { $0 } })
        ImageStore.removeUnused(keeping: used)
    }

    private static func commit(_ context: ModelContext) {
        try? context.save()
        refreshSideEffects()
    }

    private static func model(id: UUID, in context: ModelContext) -> Countdown? {
        var descriptor = FetchDescriptor<Countdown>(predicate: #Predicate { $0.id == id })
        descriptor.fetchLimit = 1
        return try? context.fetch(descriptor).first
    }

    private static func duplicateFile(_ icon: IconSpec) -> IconSpec {
        if case .image(let file) = icon, let newFile = copyImage(file) { return .image(newFile) }
        return icon
    }

    private static func copyImage(_ file: String) -> String? {
        let ext = (file as NSString).pathExtension
        let prefix = file.hasPrefix("icon") ? "icon" : "bg"
        let newName = "\(prefix)-\(UUID().uuidString).\(ext)"
        let dir = AppGroup.imagesDirectory
        do {
            try FileManager.default.copyItem(at: dir.appending(path: file), to: dir.appending(path: newName))
            return newName
        } catch { return nil }
    }
}
