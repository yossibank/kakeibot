import Core
import DesignSystem
@testable import FeatureModels
import Testing

extension EditFlowTests {
    @Test
    func namesProblemInsteadOfSaving() async {
        let source = FakeSource(problem: "名前を入れてください")
        let flow = EditFlow(source: source)

        await flow.save().value

        #expect(source.storeCount == 0)
        #expect(!flow.output.canSave)
        #expect(flow.output.saveTitle == "名前を入れてください")
        #expect(source.state.errorNotice.message == "名前を入れてください")
        #expect(flow.state.outcome.value == nil)
    }

    @Test
    func namesSaveByWhetherEditing() {
        let adding = EditFlow(source: FakeSource())
        let editing = EditFlow(source: FakeSource(isEditing: true))

        #expect(adding.output.saveTitle == "追加する")
        #expect(editing.output.saveTitle == "変更を保存")
        #expect(editing.output.canSave)
    }

    @Test
    func asksBeforeHidingChanges() async {
        let changed = EditFlow(source: FakeSource(isEditing: true, isChanged: true))
        let unchanged = EditFlow(source: FakeSource(isEditing: true))

        changed.toggleHidden()
        await unchanged.setHidden(true).value

        #expect(changed.state.prompt.current == .hideChanges)
        #expect(changed.state.outcome.value == nil)
        #expect(unchanged.state.prompt.current == nil)
        #expect(unchanged.state.outcome.value?.isHidden == true)
    }

    @Test
    func asksBeforeHidingWhenSourceAsks() {
        let source = FakeSource(
            isEditing: true,
            isChanged: true,
            asksBeforeHiding: true
        )
        let flow = EditFlow(source: source)

        flow.toggleHidden()
        let asked = flow.state.prompt.current

        flow.continueHiding()

        #expect(asked == .hide)
        #expect(flow.state.prompt.current == .hideChanges)
        #expect(flow.state.outcome.value == nil)
    }

    @Test
    func keepsSheetOpenWhenNothingToDelete() async {
        let source = FakeSource()
        let flow = EditFlow(source: source)

        await flow.delete().value

        #expect(source.removeCount == 0)
        #expect(flow.state.outcome.value == nil)
    }
}

extension EditFlowTests {
    @MainActor
    final class FakeSource: EditFlowSource {
        let state = FakeState()
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
        let errorNotice = ErrorNotice(wait: ManualWait().wait)
    }
}
