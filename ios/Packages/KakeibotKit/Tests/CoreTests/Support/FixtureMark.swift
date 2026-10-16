import Core
import Testing

struct FixtureMark: Decodable, Sendable {
    let kind: String
    let value: String
}

extension FixtureMark {
    enum Problem: Error {
        case unknownKind(String)
    }

    func mark() throws -> IconDraft.Mark {
        switch kind {
        case "glyph":
            let glyph = try #require(Icon.Glyph(rawValue: value))
            return .glyph(glyph)
        case "emoji":
            return .emoji(value)
        case "text":
            return .text(value)
        default:
            throw Problem.unknownKind(kind)
        }
    }
}
