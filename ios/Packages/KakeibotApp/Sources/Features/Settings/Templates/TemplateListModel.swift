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
        let templates = templates(isHidden: false)

        guard let movingOrder else {
            return templates
        }

        return movingOrder.compactMap { id in
            templates.first { $0.id == id }
        }
    }

    var hidden: [EntryTemplate] {
        templates(isHidden: true)
    }

    func icon(for template: EntryTemplate) -> Icon? {
        list?.icon(for: template)
    }

    func detail(for template: EntryTemplate) -> String {
        list?.detail(for: template) ?? ""
    }

    func load() async {
        do {
            templates = try await database.templates(includingHidden: true)
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

    func cancelMoving() {
        movingOrder = nil
    }

    @discardableResult
    func hide(_ id: EntryTemplate.ID) async -> Bool {
        movingOrder = nil
        let failure = Self.hideFailedMessage
        return await setHidden(id, isHidden: true, failure: failure)
    }

    func show(_ id: EntryTemplate.ID) async {
        await setHidden(id, isHidden: false, failure: Self.showFailedMessage)
    }

    func finishMoving() async {
        guard let movingOrder else {
            return
        }

        let others = templates.map(\.id).filter { !movingOrder.contains($0) }
        let ids = movingOrder + others

        do {
            try await database.reorderTemplates(ids, at: Date())
            templates = try await database.templates(includingHidden: true)
        } catch {
            errorNotice.show(Self.saveFailedMessage)
        }

        self.movingOrder = nil
    }
}

private extension TemplateListModel {
    static let loadFailedMessage = "テンプレートを読めませんでした"
    static let saveFailedMessage = "並びを保存できませんでした"
    static let hideFailedMessage = "非表示にできませんでした"
    static let showFailedMessage = "表示に戻せませんでした"

    func templates(isHidden: Bool) -> [EntryTemplate] {
        templates.filter { template in
            template.type == type && (template.archivedAt != nil) == isHidden
        }
    }

    @discardableResult
    func setHidden(
        _ id: EntryTemplate.ID,
        isHidden: Bool,
        failure: String
    ) async -> Bool {
        do {
            try await database.setTemplateHidden(
                id,
                isHidden: isHidden,
                at: Date()
            )

            templates = try await database.templates(includingHidden: true)

            return true
        } catch {
            errorNotice.show(failure)
            return false
        }
    }

    func observeTemplates() async {
        await observe(
            database.templateUpdates(includingHidden: true),
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
