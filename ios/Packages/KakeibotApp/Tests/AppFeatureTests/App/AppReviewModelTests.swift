@testable import AppFeature
import FeatureModels
import Testing

@MainActor
struct AppReviewModelTests {
    @Test
    func placesOutcomeWhenReady() async throws {
        let setup = try await AppReviewRequestTests.Setup(entries: 10, daysAgo: 3)
        let model = AppReviewModel(request: setup.request, clock: .fixed(setup.now))

        await model.ask(after: setup.recorded)
        let first = model.state.outcome
        await model.ask(after: setup.recorded)

        #expect(first != ScreenOutcome<Void>())
        #expect(model.state.outcome == first)
    }

    @Test
    func placesNoOutcomeWhileWaiting() async throws {
        let setup = try await AppReviewRequestTests.Setup(entries: 10, daysAgo: 2)
        let model = AppReviewModel(request: setup.request, clock: .fixed(setup.now))

        await model.ask(after: setup.recorded)

        #expect(model.state.outcome == ScreenOutcome<Void>())
    }
}
