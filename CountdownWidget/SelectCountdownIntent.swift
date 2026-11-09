import AppIntents
import Foundation

struct CountdownEntity: AppEntity {
    static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "Countdown")
    static let defaultQuery = CountdownEntityQuery()

    let id: UUID
    let title: String
    let symbol: String

    init(item: CountdownItem) {
        id = item.id
        title = item.displayTitle
        if case .symbol(let name) = item.icon { symbol = name } else { symbol = "hourglass" }
    }

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(title)", image: .init(systemName: symbol))
    }
}

struct CountdownEntityQuery: EntityQuery {
    func entities(for identifiers: [UUID]) async throws -> [CountdownEntity] {
        SharedStore.fetchItems(includeArchived: true)
            .filter { identifiers.contains($0.id) }
            .map(CountdownEntity.init(item:))
    }

    func suggestedEntities() async throws -> [CountdownEntity] {
        SharedStore.fetchItems().sortedForDisplay().map(CountdownEntity.init(item:))
    }

    func defaultResult() async -> CountdownEntity? {
        SharedStore.fetchItems().sortedForDisplay().first.map(CountdownEntity.init(item:))
    }
}

struct SelectCountdownIntent: WidgetConfigurationIntent {
    static let title: LocalizedStringResource = "Choose Countdown"
    static let description = IntentDescription("Pick which countdown this widget shows.")

    @Parameter(title: "Countdown")
    var countdown: CountdownEntity?

    init() {}
}
