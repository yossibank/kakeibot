import DesignSystem
@testable import Features
import Testing

@MainActor
struct ScreenModelTests {
    @Test
    func resubscribesAfterFailure() async {
        let model = Model()
        let counter = Counter()
        var received: [Int] = []

        let isFailed = await model.observe(
            Self.values(counter, failures: 2),
            failure: "失敗",
            retryDelays: Self.delays
        ) { value in
            received.append(value)
        }

        #expect(!isFailed)
        #expect(counter.attempts == 3)
        #expect(received == [1])
        #expect(model.errorNotice.message == nil)
    }

    @Test
    func stopsAtLimitWithNotice() async {
        let model = Model()
        let counter = Counter()

        let isFailed = await model.observe(
            Self.values(counter, failures: 10),
            failure: "失敗",
            retryDelays: Self.delays
        ) { _ in }

        #expect(isFailed)
        #expect(counter.attempts == 4)
        #expect(model.errorNotice.message == "失敗")
    }

    @Test
    func stopsWhenFailingRightAfterEachValue() async {
        let counter = Counter()

        let isFailed = await ScreenObservation.retry(
            Self.valueThenFailure(counter),
            retryDelays: [.zero, .zero, .zero]
        ) { _ in }

        #expect(isFailed)
        #expect(counter.attempts == 4)
    }

    @Test
    func stopsWhenCancelled() async {
        let model = Model()
        let counter = Counter()

        let task = Task {
            await model.observe(
                Self.values(counter, failures: 10),
                failure: "失敗",
                retryDelays: [.seconds(60)]
            ) { _ in }
        }

        task.cancel()
        let isFailed = await task.value

        #expect(!isFailed)
        #expect(counter.attempts <= 1)
        #expect(model.errorNotice.message == nil)
    }
}

private extension ScreenModelTests {
    struct Failure: Error {}

    final class Counter {
        var attempts = 0
    }

    @MainActor
    final class Model: ScreenModel {
        var errorNotice = ErrorNotice()
    }

    static let delays: [Duration] = [.milliseconds(1), .milliseconds(1), .milliseconds(1)]

    static func valueThenFailure(_ counter: Counter) -> AsyncThrowingStream<Int, Error> {
        counter.attempts += 1

        return AsyncThrowingStream { continuation in
            continuation.yield(1)
            continuation.finish(throwing: Failure())
        }
    }

    static func values(
        _ counter: Counter,
        failures: Int
    ) -> AsyncThrowingStream<Int, Error> {
        counter.attempts += 1
        let isFailing = counter.attempts <= failures

        return AsyncThrowingStream { continuation in
            if isFailing {
                continuation.finish(throwing: Failure())
            } else {
                continuation.yield(1)
                continuation.finish()
            }
        }
    }
}
