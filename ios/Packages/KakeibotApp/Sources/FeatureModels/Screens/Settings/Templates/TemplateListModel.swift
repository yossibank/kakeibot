import Core
import DesignSystem
import Foundation
import Observation
import Store

@MainActor
@Observable
public final class TemplateListModel {
    public let state: State
    public let input: Input
    public let output: Output

    public let dependencies: ScreenParts

    public init(parts: ScreenParts) {
        let state = State()
        let input = Input()

        self.state = state
        self.input = input
        self.output = Output(input: input, state: state)
        self.dependencies = parts
    }
}

public extension TemplateListModel {
    @MainActor
    @Observable
    final class State: SettingsBoardState {
        public var errorNotice = ErrorNotice()

        public var type: Entry.Kind = .expense
        public var movingOrder: [EntryTemplate.ID]?
        public var removed = SettingsBoardRemoved<EntryTemplate.ID>()
    }

    @MainActor
    @Observable
    final class Input: SettingsBoardInput {
        public internal(set) var snapshot: [EntryTemplate]?
        public internal(set) var list: EntryList?

        public let hint = SettingsFoldInput.hint(.templates)
        public let hiddenList = SettingsFoldInput.hiddenList(.templates)
    }

    @MainActor
    final class Output: SettingsBoardOutput {
        public let state: State

        let input: Input

        public var items: [EntryTemplate] {
            let templates = input.snapshot ?? []
            return templates.filter { $0.type == state.type }
        }

        init(
            input: Input,
            state: State
        ) {
            self.input = input
            self.state = state
        }

        public func icon(for template: EntryTemplate) -> Icon? {
            input.list?.icon(for: template)
        }

        public func detail(for template: EntryTemplate) -> String {
            input.list?.detail(for: template) ?? ""
        }
    }

    func load() async {
        do {
            input.snapshot = try await read()
            input.list = try await dependencies.database.entryList()
        } catch {
            state.errorNotice.show(Self.loadFailedMessage)
        }
    }

    func observe() async {
        await observeAll([
            {
                await self.observe(self.updates(), into: \.input.snapshot)
            },
            {
                await self.observe(
                    self.dependencies.database.entryListUpdates(),
                    into: \.input.list
                )
            }
        ])
    }
}

extension TemplateListModel: SettingsBoardDatabaseModel {
    public typealias Item = EntryTemplate

    public static let loadFailedMessage = "テンプレートを読めませんでした"

    public func read() async throws -> [EntryTemplate] {
        try await dependencies.database.templates(includingHidden: true)
    }

    public func updates() -> some AsyncSequence<[EntryTemplate], any Error> {
        dependencies.database.templateUpdates(includingHidden: true)
    }
}

extension TemplateListModel: SettingsBoardModel {
    public func reload() async {
        do {
            input.snapshot = try await read()
        } catch {
            state.errorNotice.show(Self.loadFailedMessage)
        }
    }

    public func saveOrder(_ ids: [EntryTemplate.ID]) async throws {
        let others = (input.snapshot ?? []).map(\.id).filter { !ids.contains($0) }
        let ordered = ids + others

        try await dependencies.database.reorder(ordered, at: dependencies.clock.now)
    }

    public func remove(_ id: EntryTemplate.ID) async throws -> Deletion {
        try await dependencies.database.deleteTemplate(id)
    }
}
