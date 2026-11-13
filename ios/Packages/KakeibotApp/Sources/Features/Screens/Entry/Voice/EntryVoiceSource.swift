import Foundation

struct EntryVoiceTranscript: Equatable, Sendable {
    var settled = ""
    var pending = ""
    var alternatives: [String] = []

    var text: String {
        settled + pending
    }

    var isEmpty: Bool {
        text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

struct EntryVoiceQuestion: Equatable, Sendable {
    let text: String
    let categories: [String]
    let wallets: [String]
    let examples: [String]
}

enum EntryVoiceEvent: Equatable, Sendable {
    case transcript(EntryVoiceTranscript)
}

@MainActor
protocol EntryVoiceSource: AnyObject {
    func start(
        hints: [String],
        _ onEvent: @escaping @MainActor (EntryVoiceEvent) -> Void
    ) async throws
    func finish() async
    func cancel() async
}
