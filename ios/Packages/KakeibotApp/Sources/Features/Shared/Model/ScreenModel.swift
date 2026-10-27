import DesignSystem

@MainActor
protocol ScreenModel: AnyObject {
    var errorNotice: ErrorNotice { get set }
}

public enum ScreenObservation {
    public static let retryDelays: [Duration] = [.seconds(1), .seconds(2), .seconds(4)]

    public static func retry<Values: AsyncSequence>(
        _ values: @autoclosure () -> Values,
        retryDelays: [Duration] = ScreenObservation.retryDelays,
        isolation: isolated (any Actor)? = #isolation,
        receive: nonisolated(nonsending) (Values.Element) async -> Void
    ) async -> Bool {
        var attempt = 0

        while true {
            do {
                for try await value in values() {
                    attempt = 0
                    await receive(value)
                }

                return false
            } catch {
                if error is CancellationError || Task.isCancelled {
                    return false
                }

                guard attempt < retryDelays.count else {
                    return true
                }

                do {
                    try await Task.sleep(for: retryDelays[attempt])
                } catch {
                    return false
                }

                attempt += 1
            }
        }
    }
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
            errorNotice.show(message)
        }

        return isFailed
    }
}
