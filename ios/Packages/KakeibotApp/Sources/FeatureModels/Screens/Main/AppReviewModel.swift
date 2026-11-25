import Observation

@MainActor
@Observable
public final class AppReviewModel: ScreenPerforming {
    public let state = State()

    let dependencies: Dependencies

    public convenience init(parts: ScreenParts) {
        let request = AppReviewRequest(database: parts.database)

        self.init(
            request: request,
            clock: parts.clock,
            askDelay: MainModel.sheetCloseDelay
        )
    }

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

public extension AppReviewModel {
    @MainActor
    @Observable
    final class State {
        public var outcome = ScreenOutcome<Void>()
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

extension AppReviewModel {
    struct Dependencies {
        let request: AppReviewRequest
        let clock: ScreenClock
        let askDelay: Duration
    }
}
