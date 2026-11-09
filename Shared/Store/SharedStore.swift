import Foundation
import SwiftData

/// Single local SQLite database (via SwiftData) shared by app and widget.
enum SharedStore {
    static let container: ModelContainer = {
        let schema = Schema([Countdown.self])
        let configuration = ModelConfiguration(
            "Countdown",
            schema: schema,
            url: AppGroup.storeURL,
            allowsSave: true,
            cloudKitDatabase: .none
        )
        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Could not open the local database: \(error)")
        }
    }()

    /// Snapshot of all countdowns as value types (safe to hand to widgets / background work).
    static func fetchItems(includeArchived: Bool = false) -> [CountdownItem] {
        let context = ModelContext(container)
        let descriptor = FetchDescriptor<Countdown>(sortBy: [SortDescriptor(\.sortOrder), SortDescriptor(\.createdAt)])
        let models = (try? context.fetch(descriptor)) ?? []
        return models
            .filter { includeArchived || !$0.isArchived }
            .map(\.item)
    }

    static func fetchItem(id: UUID) -> CountdownItem? {
        let context = ModelContext(container)
        var descriptor = FetchDescriptor<Countdown>(predicate: #Predicate { $0.id == id })
        descriptor.fetchLimit = 1
        return (try? context.fetch(descriptor))?.first?.item
    }
}
