import Core
import DesignSystem
import Foundation
import Observation
import Store

@MainActor
@Observable
public final class TemplateListModel: ScreenModel {
    public var type: Entry.Kind = .expense

    public private(set) var templates: [EntryTemplate] = []
    public private(set) var movingOrder: [EntryTemplate.ID]?
    public private(set) var list: EntryList?

    public internal(set) var errorNotice = ErrorNotice()

    private let database: AppDatabase

    public init(database: AppDatabase) {
        self.database = database
    }
}

public extension TemplateListModel {
    var shown: [EntryTemplate] {
        let templates = templates.filter { $0.type == type }

        guard let movingOrder else {
            return templates
        }

        return movingOrder.compactMap { id in
            templates.first { $0.id == id }
        }
    }

    func icon(for template: EntryTemplate) -> Icon? {
        list?.icon(for: template)
    }

    func detail(for template: EntryTemplate) -> String {
        list?.detail(for: template) ?? ""
    }

    func load() async {
        do {
            templates = try await database.templates()
            list = try await database.entryList()
        } catch {
            errorNotice.show(Self.loadFailedMessage)
        }
    }

    func observe() async {
        await withDiscardingTaskGroup { group in
            group.addTask {
                await self.observeTemplates()
            }

            group.addTask {
                await self.observeList()
            }
        }
    }

    func move(
        _ id: EntryTemplate.ID,
        to index: Int
    ) {
        var order = movingOrder ?? shown.map(\.id)

        guard let from = order.firstIndex(of: id) else {
            return
        }

        let to = min(max(index, 0), order.count - 1)

        guard from != to else {
            return
        }

        order.remove(at: from)
        order.insert(id, at: to)
        movingOrder = order
    }

    func finishMoving() async {
        guard let movingOrder else {
            return
        }

        let others = templates.filter { $0.type != type }.map(\.id)
        let ids = movingOrder + others

        do {
            try await database.reorderTemplates(ids, at: Date())
            templates = try await database.templates()
        } catch {
            errorNotice.show(Self.saveFailedMessage)
        }

        self.movingOrder = nil
    }
}

private extension TemplateListModel {
    static let loadFailedMessage = "テンプレートを読めませんでした"
    static let saveFailedMessage = "並びを保存できませんでした"

    func observeTemplates() async {
        await observe(
            database.templateUpdates(),
            failure: Self.loadFailedMessage
        ) { templates in
            self.templates = templates
        }
    }

    func observeList() async {
        await observe(
            database.entryListUpdates(),
            failure: Self.loadFailedMessage
        ) { list in
            self.list = list
        }
    }
}
