import Foundation

enum EntryVoiceEvent: Equatable, Sendable {
    case transcript(EntryVoiceTranscript)
    case level(Double)
}
