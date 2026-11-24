import Foundation

@MainActor
protocol EntryVoiceSource: AnyObject {
    func start(
        hints: [String],
        _ onEvent: @escaping @MainActor (EntryVoiceEvent) -> Void
    ) async throws
    func finish() async
    func cancel() async
}
