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
    public var movingOrder: [EntryTemplate.ID]?
    public private(set) var list: EntryList?

    public var errorNotice = ErrorNotice()

    private let database: AppDatabase

    public init(database: AppDatabase) {
        self.database = database
    }
}

public extension TemplateListModel {
    var visible: [EntryTemplate] {
        templates(isHidden: false)
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
}

private extension TemplateListModel {
    static let loadFailedMessage = "テンプレートを読めませんでした"

    func templates(isHidden: Bool) -> [EntryTemplate] {
        templates.filter { template in
            template.type == type && (template.archivedAt != nil) == isHidden
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

extension TemplateListModel: SettingsBoardModel {
    public func reload() async {
        do {
            templates = try await database.templates(includingHidden: true)
        } catch {
            errorNotice.show(Self.loadFailedMessage)
        }
    }

    public func saveOrder(_ ids: [EntryTemplate.ID]) async throws {
        let others = templates.map(\.id).filter { !ids.contains($0) }

        try await database.reorderTemplates(ids + others, at: Date())
    }

    public func saveHidden(
        _ id: EntryTemplate.ID,
        isHidden: Bool
    ) async throws {
        try await database.setTemplateHidden(
            id,
            isHidden: isHidden,
            at: Date()
        )
    }

    public func remove(_ id: EntryTemplate.ID) async throws -> Deletion {
        try await database.deleteTemplate(id)
    }

    public func restoreRemoved(_ deletion: Deletion) async throws {
        try await database.restore(deletion)
    }
}
