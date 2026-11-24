import Foundation

public struct EntryVoiceTranscript: Equatable, Sendable {
    public var settled = ""
    public var pending = ""

    var alternatives: [String] = []

    public var text: String {
        settled + pending
    }

    public var isEmpty: Bool {
        text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
