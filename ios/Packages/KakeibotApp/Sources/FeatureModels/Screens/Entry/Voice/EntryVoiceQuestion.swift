import Foundation

struct EntryVoiceQuestion: Equatable, Sendable {
    let text: String
    let categories: [String]
    let wallets: [String]
    let examples: [String]
}
