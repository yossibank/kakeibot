import DesignSystem

@MainActor
public protocol ScreenModel: ScreenPerforming {
    associatedtype State: NoticesHolding

    static var loadFailedMessage: String { get }

    var state: State { get }
}

extension ScreenModel {
    @discardableResult
    func observe<Values: AsyncSequence>(
        _ values: @autoclosure () -> Values,
        failure message: String,
        retryDelays: [Duration] = ScreenObservation.retryDelays,
        receive: (Values.Element) -> Void
    ) async -> Bool {
        let isFailed = await ScreenObservation.retry(
            values(),
            retryDelays: retryDelays,
            receive: receive
        )

        if isFailed {
            state.errorNotice.show(message)
        }

        return isFailed
    }

    func observe<Values: AsyncSequence>(
        _ values: @autoclosure () -> Values,
        into keyPath: ReferenceWritableKeyPath<Self, Values.Element>
    ) async {
        await observe(values(), failure: Self.loadFailedMessage) { value in
            self[keyPath: keyPath] = value
        }
    }

    func observe<Values: AsyncSequence>(
        _ values: @autoclosure () -> Values,
        into keyPath: ReferenceWritableKeyPath<Self, Values.Element?>
    ) async {
        await observe(values(), failure: Self.loadFailedMessage) { value in
            self[keyPath: keyPath] = value
        }
    }

    func observe<Values: AsyncSequence>(
        _ values: @autoclosure () -> Values,
        into keyPath: ReferenceWritableKeyPath<Self, Loadable<Values.Element>>,
        receive: (Values.Element) -> Void = { _ in }
    ) async {
        self[keyPath: keyPath] = self[keyPath: keyPath].retrying

        let isFailed = await observe(values(), failure: Self.loadFailedMessage) { value in
            self[keyPath: keyPath] = .loaded(value)
            receive(value)
        }

        if isFailed {
            self[keyPath: keyPath] = .failed
        }
    }

    func observeAll(_ observations: [@MainActor @Sendable () async -> Void]) async {
        await ScreenObservation.all(observations)
    }
}
