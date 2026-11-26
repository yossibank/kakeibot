import Core
import DesignSystem
import Foundation
import Observation
import Store

@MainActor
@Observable
public final class CategoryListModel {
    public let state: State
    public let input: SettingsBoardSnapshotInput<CategoryList>
    public let output: Output
    public let dependencies: ScreenParts

    public init(
        parts: ScreenParts,
        kind: EntryCategory.Kind = .expense
    ) {
        let state = State(kind: kind)
        let input = SettingsBoardSnapshotInput<CategoryList>(screen: .categories)

        self.state = state
        self.input = input
        self.output = Output(input: input, state: state)
        self.dependencies = parts
    }
}

public extension CategoryListModel {
    enum Destination: Hashable, Sendable {
        case new(EntryCategory.Kind)
        case edit(EntryCategory.Kind, EntryCategory.ID)
    }

    @MainActor
    @Observable
    final class State: SettingsBoardState {
        public var errorNotice = ErrorNotice()
        public var kind: EntryCategory.Kind
        public var movingOrder: [EntryCategory.ID]?
        public var removed = SettingsBoardRemoved<EntryCategory.ID>()
        public var shown = SettingsBoardShown<EntryCategory.ID, Destination>()

        init(kind: EntryCategory.Kind) {
            self.kind = kind
        }
    }

    @MainActor
    final class Output: SettingsBoardOutput {
        public let state: State

        let input: SettingsBoardSnapshotInput<CategoryList>

        init(
            input: SettingsBoardSnapshotInput<CategoryList>,
            state: State
        ) {
            self.input = input
            self.state = state
        }
    }
}

public extension CategoryListModel.Output {
    var items: [EntryCategory] {
        let categories = input.snapshot?.categories ?? []
        return categories.filter { $0.kind == state.kind }
    }

    func icon(for category: EntryCategory) -> Icon? {
        input.snapshot?.icons[category.iconId]
    }
}

extension CategoryListModel: SettingsBoardListModel {
    public typealias Item = EntryCategory

    public static let loadFailedMessage = "カテゴリを読めませんでした"

    public func read() async throws -> CategoryList {
        try await dependencies.database.categoryList()
    }

    public func updates() -> some AsyncSequence<CategoryList, any Error> {
        dependencies.database.categoryListUpdates()
    }
}

extension CategoryListModel: SettingsBoardModel {
    public func remove(_ id: EntryCategory.ID) async throws -> Deletion {
        try await dependencies.database.deleteCategory(
            id,
            at: dependencies.clock.now
        )
    }

    public func isInUse(_ error: any Error) -> Bool {
        error as? AppDatabase.CategoryWriteError == .hasEntries
    }
}
