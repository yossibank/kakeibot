import DesignSystem

@MainActor
protocol ScreenModel: AnyObject {
    var errorNotice: ErrorNotice { get set }
}

enum ScreenObservation {
    static let retryDelays: [Duration] = [.seconds(1), .seconds(2), .seconds(4)]
}

extension ScreenModel {
    @discardableResult
    func observe<Values: AsyncSequence>(
        _ values: @autoclosure () -> Values,
        failure message: String,
        retryDelays: [Duration] = ScreenObservation.retryDelays,
        receive: (Values.Element) -> Void
    ) async -> Bool {
        var attempt = 0

        while true {
            do {
                for try await value in values() {
                    attempt = 0
                    receive(value)
                }

                return false
            } catch {
                if error is CancellationError || Task.isCancelled {
                    return false
                }

                guard attempt < retryDelays.count else {
                    errorNotice.show(message)
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
