import Foundation

public struct EntryVoiceTranscript: Equatable, Sendable {
    public var settled = ""
    public var pending = ""

    var alternatives: [String] = []
}

public extension EntryVoiceTranscript {
    var text: String {
        settled + pending
    }

    var isEmpty: Bool {
        text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
