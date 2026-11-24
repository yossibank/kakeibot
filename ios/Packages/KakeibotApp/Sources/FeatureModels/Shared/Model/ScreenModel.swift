import DesignSystem

@MainActor
public protocol ScreenModel: AnyObject {
    associatedtype State: NoticeHolding

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
        into keyPath: ReferenceWritableKeyPath<Self, Values.Element?>,
        failing failed: ReferenceWritableKeyPath<Self, Bool>
    ) async {
        self[keyPath: failed] = false

        self[keyPath: failed] = await observe(values(), failure: Self.loadFailedMessage) { value in
            self[keyPath: keyPath] = value
        }
    }

    func observeAll(_ observations: [@MainActor @Sendable () async -> Void]) async {
        await withDiscardingTaskGroup { group in
            for observation in observations {
                group.addTask {
                    await observation()
                }
            }
        }
    }
}
