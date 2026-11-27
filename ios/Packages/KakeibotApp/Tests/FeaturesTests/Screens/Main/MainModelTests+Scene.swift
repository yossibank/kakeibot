import Core
@testable import FeatureModels
import Store
import Testing

extension MainModelTests {
    @Test
    func finishesWarmingEntryAfterWaiting() async throws {
        let setup = try await TemplateSetup()
        let model = Self.model(setup)
        let before = model.state.entry.isWarming

        await model.warmUpEntry()

        #expect(before)
        #expect(!model.state.entry.isWarming)
    }

    @Test
    func restartsObservationWhenReturningFromBackground() async throws {
        let setup = try await TemplateSetup()
        let model = Self.model(setup)

        model.state.changeScene(to: .inactive)
        model.state.changeScene(to: .active)
        let afterInactive = model.state.round.count
        model.state.changeScene(to: .background)
        model.state.changeScene(to: .inactive)
        model.state.changeScene(to: .active)
        let afterBackground = model.state.round.count
        model.state.changeScene(to: .active)

        #expect(afterInactive == 0)
        #expect(afterBackground == 1)
        #expect(model.state.round.count == 1)
    }

    @Test
    func restartsObservationOnRetry() async throws {
        let setup = try await TemplateSetup()
        let model = Self.model(setup)

        model.state.round.restart()

        #expect(model.state.round.count == 1)
    }

    @Test
    func advancesNoticeRoundToHideTabNotices() async throws {
        let setup = try await TemplateSetup()
        let model = Self.model(setup)

        model.state.hideTabNotices()

        #expect(model.state.notices.round == 1)
        #expect(model.state.round.count == 0)
    }

    @Test
    func keepsDeletionForUndo() async throws {
        let setup = try await TemplateSetup()
        let model = Self.model(setup)

        #expect(model.state.notices.undo.state.notices.deletion.current == nil)
        #expect(model.state.notices.undo.state.notices.error.message == nil)
    }
}
