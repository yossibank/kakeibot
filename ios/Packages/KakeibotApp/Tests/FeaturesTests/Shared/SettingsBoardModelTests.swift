import DesignSystem
import Features
import Store
import Testing

@MainActor
struct SettingsBoardModelTests {
    @Test
    func keepsMoveInsideTheBoard() {
        let board = FakeBoard(visible: ["a", "b", "c"])

        board.move("c", to: -5)
        let toStart = board.shown.map(\.id)
        board.move("c", to: 99)
        let toEnd = board.shown.map(\.id)

        #expect(toStart == ["c", "a", "b"])
        #expect(toEnd == ["a", "b", "c"])
    }

    @Test
    func ignoresMoveToSamePlaceOrUnknownItem() {
        let board = FakeBoard(visible: ["a", "b", "c"])

        board.move("b", to: 1)
        let samePlace = board.movingOrder
        board.move("x", to: 0)

        #expect(samePlace == nil)
        #expect(board.movingOrder == nil)
    }

    @Test
    func deletesNothingWhenNoneAreHidden() async {
        let board = FakeBoard(visible: ["a"])

        let result = await board.deleteHidden()

        #expect(result.deletion == nil)
        #expect(board.removed.isEmpty)
        #expect(board.errorNotice.message == nil)
    }

    @Test
    func deletesEveryHiddenItem() async {
        let board = FakeBoard(visible: ["a"], hidden: ["x", "y"])
        board.move("a", to: 0)

        let result = await board.deleteHidden()

        #expect(result.deletion != nil)
        #expect(result.note(for: result.deletion) == nil)
        #expect(board.removed == ["x", "y"])
        #expect(board.reloadCount == 1)
        #expect(board.movingOrder == nil)
        #expect(board.errorNotice.message == nil)
    }

    @Test
    func notesHiddenItemsInUseWithTheDeletion() async {
        let board = FakeBoard(visible: ["a"], hidden: ["x", "y"], inUse: ["y"])

        let result = await board.deleteHidden()
        let other = Deletion(merging: [])

        #expect(result.deletion != nil)
        #expect(board.removed == ["x"])
        #expect(result.note(for: result.deletion) == "記録がある 1 件は残しました")
        #expect(result.note(for: other) == nil)
        #expect(board.errorNotice.message == nil)
    }

    @Test
    func informsWhenEveryHiddenItemIsInUse() async {
        let board = FakeBoard(visible: ["a"], hidden: ["x", "y"], inUse: ["x", "y"])

        let result = await board.deleteHidden()

        #expect(result.deletion == nil)
        #expect(board.errorNotice.message == "記録があるので削除しませんでした")
        #expect(board.errorNotice.tone == .info)
    }

    @Test
    func tellsWhenSomeHiddenItemsCannotBeDeleted() async {
        let board = FakeBoard(visible: ["a"], hidden: ["x", "y"], failing: ["x", "y"])

        let result = await board.deleteHidden()

        #expect(result.deletion == nil)
        #expect(board.errorNotice.message == "削除できないものがありました")
        #expect(board.errorNotice.tone == .error)
    }
}

extension SettingsBoardModelTests {
    struct Item: Identifiable {
        let id: String
    }

    struct InUse: Error {}

    struct Failure: Error {}

    @MainActor
    final class FakeBoard: SettingsBoardModel {
        var movingOrder: [String]?
        var errorNotice = ErrorNotice()

        private(set) var removed: [String] = []
        private(set) var reloadCount = 0

        let visible: [Item]
        let hidden: [Item]

        private let inUse: Set<String>
        private let failing: Set<String>

        init(
            visible: [String],
            hidden: [String] = [],
            inUse: Set<String> = [],
            failing: Set<String> = []
        ) {
            self.visible = visible.map(Item.init)
            self.hidden = hidden.map(Item.init)
            self.inUse = inUse
            self.failing = failing
        }
    }
}

extension SettingsBoardModelTests.FakeBoard {
    func reload() async {
        reloadCount += 1
    }

    func saveOrder(_: [String]) async throws {}

    func remove(_ id: String) async throws -> Deletion {
        if inUse.contains(id) {
            throw SettingsBoardModelTests.InUse()
        }

        if failing.contains(id) {
            throw SettingsBoardModelTests.Failure()
        }

        removed.append(id)
        return Deletion(merging: [])
    }

    func restoreRemoved(_: Deletion) async throws {}

    func isInUse(_ error: any Error) -> Bool {
        error is SettingsBoardModelTests.InUse
    }

    func saveHidden(
        _: String,
        isHidden _: Bool
    ) async throws {}
}
