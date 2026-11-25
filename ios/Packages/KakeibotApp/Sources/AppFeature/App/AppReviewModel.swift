import FeatureModels
import Observation
import Store

@MainActor
@Observable
final class AppReviewModel: ScreenPerforming {
    let state = State()

    let dependencies: Dependencies

    init(
        request: AppReviewRequest,
        clock: ScreenClock,
        askDelay: Duration = .zero
    ) {
        self.dependencies = Dependencies(
            request: request,
            clock: clock,
            askDelay: askDelay
        )
    }
}

extension AppReviewModel {
    @MainActor
    @Observable
    final class State {
        var outcome = ScreenOutcome<Void>()
    }

    struct Dependencies {
        let request: AppReviewRequest
        let clock: ScreenClock
        let askDelay: Duration
    }

    convenience init(
        database: AppDatabase,
        clock: ScreenClock
    ) {
        let request = AppReviewRequest(database: database)

        self.init(
            request: request,
            clock: clock,
            askDelay: MainView.sheetCloseDuration
        )
    }

    func ask(after change: EntryChange) async {
        let now = dependencies.clock.now

        guard await dependencies.request.shouldAsk(after: change, at: now) else {
            return
        }

        try? await Task.sleep(for: dependencies.askDelay)
        state.outcome.send(())
    }
}
