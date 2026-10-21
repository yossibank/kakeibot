import DesignSystem

@MainActor
protocol ScreenModel: AnyObject {
    var errorNotice: ErrorNotice { get set }
}

extension ScreenModel {
    func observe<Values: AsyncSequence>(
        _ values: Values,
        failure message: String,
        receive: (Values.Element) -> Void
    ) async {
        do {
            for try await value in values {
                receive(value)
            }
        } catch {
            errorNotice.show(message)
        }
    }
}
