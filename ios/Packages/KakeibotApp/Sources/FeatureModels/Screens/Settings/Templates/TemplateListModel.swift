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
        let state = State(wait: parts.wait)
        let input = Input()

        self.state = state
        self.input = input
        self.output = Output(input: input, state: state)
        self.dependencies = parts
    }
}

public extension TemplateListModel {
    enum Destination: Hashable, Sendable {
        case new(Entry.Kind)
        case edit(Entry.Kind, EntryTemplate.ID)
    }

    struct Fields: ScreenEditable {
        public var type: Entry.Kind = .expense
    }

    typealias Presented = SettingsBoardShown<EntryTemplate.ID, Destination>

    @MainActor
    @Observable
    final class State: SettingsBoardState {
        public var fields = Fields()
        public var presented = Presented()

        public private(set) var movingOrder: [EntryTemplate.ID]?

        public let errorNotice: ErrorNotice
        public let removed: SettingsBoardRemoved<EntryTemplate.ID>

        init(wait: ScreenWait) {
            self.errorNotice = ErrorNotice(wait: wait)
            self.removed = SettingsBoardRemoved(wait: wait)
        }
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

        init(
            input: Input,
            state: State
        ) {
            self.input = input
            self.state = state
        }
    }
}

public extension TemplateListModel {
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

public extension TemplateListModel.Output {
    var items: [EntryTemplate] {
        let templates = input.snapshot ?? []
        return templates.filter { $0.type == state.fields.type }
    }

    func icon(for template: EntryTemplate) -> Icon? {
        input.list?.icon(for: template)
    }

    func detail(for template: EntryTemplate) -> String {
        input.list?.detail(for: template) ?? ""
    }
}

public extension TemplateListModel.State {
    func setMovingOrder(_ order: [EntryTemplate.ID]?) {
        movingOrder = order
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
