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

    let dependencies: SettingsBoardDependencies

    public init(
        database: AppDatabase,
        clock: ScreenClock,
        kind: EntryCategory.Kind = .expense
    ) {
        let state = State(kind: kind)
        let input = SettingsBoardSnapshotInput<CategoryList>()

        self.state = state
        self.input = input
        self.output = Output(input: input, state: state)
        self.dependencies = SettingsBoardDependencies(database: database, clock: clock)
    }
}

public extension CategoryListModel {
    @MainActor
    @Observable
    final class State: SettingsBoardState {
        public var errorNotice = ErrorNotice()

        public var kind: EntryCategory.Kind
        public var movingOrder: [EntryCategory.ID]?

        init(kind: EntryCategory.Kind) {
            self.kind = kind
        }
    }

    @MainActor
    final class Output: SettingsBoardOutput {
        let input: SettingsBoardSnapshotInput<CategoryList>
        let state: State

        var items: [EntryCategory] {
            let categories = input.snapshot?.categories ?? []
            return categories.filter { $0.kind == state.kind }
        }

        init(
            input: SettingsBoardSnapshotInput<CategoryList>,
            state: State
        ) {
            self.input = input
            self.state = state
        }

        public func icon(for category: EntryCategory) -> Icon? {
            input.snapshot?.icons[category.iconId]
        }
    }
}

extension CategoryListModel: SettingsBoardListModel {
    typealias Item = EntryCategory

    static let loadFailedMessage = "カテゴリを読めませんでした"

    func read() async throws -> CategoryList {
        try await dependencies.database.categoryList()
    }

    func updates() -> some AsyncSequence<CategoryList, any Error> {
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
