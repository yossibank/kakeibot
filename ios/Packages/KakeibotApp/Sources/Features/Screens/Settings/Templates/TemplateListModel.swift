import Core
import DesignSystem
import Foundation
import Observation
import Store

@MainActor
@Observable
public final class TemplateListModel {
    public var type: Entry.Kind = .expense
    public var movingOrder: [EntryTemplate.ID]?
    public var errorNotice = ErrorNotice()

    public internal(set) var snapshot: [EntryTemplate]?

    public private(set) var list: EntryList?

    private let database: AppDatabase

    public init(database: AppDatabase) {
        self.database = database
    }
}

public extension TemplateListModel {
    func icon(for template: EntryTemplate) -> Icon? {
        list?.icon(for: template)
    }

    func detail(for template: EntryTemplate) -> String {
        list?.detail(for: template) ?? ""
    }

    func load() async {
        do {
            snapshot = try await read()
            list = try await database.entryList()
        } catch {
            errorNotice.show(Self.loadFailedMessage)
        }
    }

    func observe() async {
        await observeAll([
            {
                await self.observe(self.updates(), into: \.snapshot)
            },
            {
                await self.observe(self.database.entryListUpdates(), into: \.list)
            }
        ])
    }
}

extension TemplateListModel: SettingsBoardDatabaseModel {
    typealias Item = EntryTemplate

    static let loadFailedMessage = "テンプレートを読めませんでした"

    func read() async throws -> [EntryTemplate] {
        try await database.templates(includingHidden: true)
    }

    func updates() -> some AsyncSequence<[EntryTemplate], any Error> {
        database.templateUpdates(includingHidden: true)
    }

    func items(in snapshot: [EntryTemplate]) -> [EntryTemplate] {
        snapshot.filter { $0.type == type }
    }

    func isHidden(_ item: EntryTemplate) -> Bool {
        item.archivedAt != nil
    }
}

extension TemplateListModel: SettingsBoardModel {
    public func reload() async {
        do {
            snapshot = try await read()
        } catch {
            errorNotice.show(Self.loadFailedMessage)
        }
    }

    public func saveOrder(_ ids: [EntryTemplate.ID]) async throws {
        let others = (snapshot ?? []).map(\.id).filter { !ids.contains($0) }
        let ordered = ids + others

        try await database.reorderTemplates(ordered, at: Date())
    }

    public func saveHidden(
        _ id: EntryTemplate.ID,
        isHidden: Bool
    ) async throws {
        try await database.setTemplateHidden(id, isHidden: isHidden, at: Date())
    }

    public func remove(_ id: EntryTemplate.ID) async throws -> Deletion {
        try await database.deleteTemplate(id)
    }

    public func restoreRemoved(_ deletion: Deletion) async throws {
        try await database.restore(deletion)
    }
}
