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
