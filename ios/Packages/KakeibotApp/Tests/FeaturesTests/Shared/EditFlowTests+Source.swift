import Core
import DesignSystem
@testable import FeatureModels
import Testing

extension EditFlowTests {
    @Test
    func namesProblemInsteadOfSaving() async {
        let source = FakeSource(problem: "名前を入れてください")

        await source.flow.save().value

        #expect(source.storeCount == 0)
        #expect(!source.flow.output.canSave)
        #expect(source.flow.output.saveTitle == "名前を入れてください")
        #expect(source.state.errorNotice.message == "名前を入れてください")
        #expect(source.flow.state.outcome.value == nil)
    }

    @Test
    func namesSaveByWhetherEditing() {
        let adding = FakeSource()
        let editing = FakeSource(isEditing: true)

        #expect(adding.flow.output.saveTitle == "追加する")
        #expect(editing.flow.output.saveTitle == "変更を保存")
        #expect(editing.flow.output.canSave)
    }

    @Test
    func asksBeforeHidingChanges() async {
        let changed = FakeSource(isEditing: true, isChanged: true)
        let unchanged = FakeSource(isEditing: true)

        changed.flow.toggleHidden()
        await unchanged.flow.setHidden(true).value

        #expect(changed.flow.state.prompt.current == .hideChanges)
        #expect(changed.flow.state.outcome.value == nil)
        #expect(unchanged.flow.state.prompt.current == nil)
        #expect(unchanged.flow.state.outcome.value?.isHidden == true)
    }

    @Test
    func asksBeforeHidingWhenSourceAsks() {
        let source = FakeSource(
            isEditing: true,
            isChanged: true,
            asksBeforeHiding: true
        )

        source.flow.toggleHidden()
        let asked = source.flow.state.prompt.current

        source.flow.continueHiding()

        #expect(asked == .hide)
        #expect(source.flow.state.prompt.current == .hideChanges)
        #expect(source.flow.state.outcome.value == nil)
    }

    @Test
    func keepsSheetOpenWhenNothingToDelete() async {
        let source = FakeSource()

        await source.flow.delete().value

        #expect(source.removeCount == 0)
        #expect(source.flow.state.outcome.value == nil)
    }
}

extension EditFlowTests {
    @MainActor
    final class FakeSource: EditFlowSource {
        let state = FakeState()
        let flow = EditFlow<String>()
        let isEditing: Bool
        let isChanged: Bool
        let problem: String?
        let asksBeforeHiding: Bool

        private(set) var storeCount = 0
        private(set) var removeCount = 0

        init(
            isEditing: Bool = false,
            isChanged: Bool = false,
            problem: String? = nil,
            asksBeforeHiding: Bool = false
        ) {
            self.isEditing = isEditing
            self.isChanged = isChanged
            self.problem = problem
            self.asksBeforeHiding = asksBeforeHiding

            flow.connect(self)
        }

        func store() async -> String? {
            storeCount += 1
            return "保存した"
        }

        func remove() async throws -> Deletion? {
            removeCount += 1
            return nil
        }
    }

    @MainActor
    final class FakeState: NoticeHolding {
        var errorNotice = ErrorNotice()
    }
}
