import Foundation

public struct IconDraft: Draft, Hashable, Sendable {
    public var mark: Mark
    public var color: String

    public init(
        mark: Mark,
        color: String
    ) {
        self.mark = mark
        self.color = color
    }

    public init(_ icon: Icon) {
        let mark = Mark(icon)

        self.init(mark: mark, color: icon.color)
    }
}

public extension IconDraft {
    enum Mark: Hashable, Sendable {
        case glyph(Icon.Glyph)
        case emoji(String)
        case text(String)

        public init(_ icon: Icon) {
            let emoji = icon.emoji ?? ""

            if let glyph = icon.glyph {
                self = .glyph(glyph)
            } else if !emoji.isEmpty {
                self = .emoji(emoji)
            } else {
                self = .text(icon.text ?? "")
            }
        }
    }

    static let maxTextLength = 3

    var problems: [DraftProblem] {
        let colorProblems: [DraftProblem] = isValidColor ? [] : [.invalidColor]
        return markProblems + colorProblems
    }

    func newIcon(at now: Date) throws -> Icon {
        try validate()

        return Icon(
            emoji: emoji,
            text: text,
            glyph: glyph,
            color: color,
            createdAt: now,
            updatedAt: now
        )
    }

    func applied(
        to icon: Icon,
        at now: Date
    ) throws -> Icon {
        try validate()

        var updated = icon

        updated.emoji = emoji
        updated.text = text
        updated.glyph = glyph
        updated.color = color
        updated.updatedAt = now

        return updated
    }
}

private extension IconDraft {
    var markProblems: [DraftProblem] {
        switch mark {
        case .glyph:
            return []

        case let .emoji(value):
            return value.trimmed.isEmpty ? [.emptyMark] : []

        case let .text(value):
            let trimmed = value.trimmed

            if trimmed.isEmpty {
                return [.emptyMark]
            }

            return trimmed.count > Self.maxTextLength ? [.textTooLong] : []
        }
    }

    var isValidColor: Bool {
        let digits = color.dropFirst()

        return color.hasPrefix("#")
            && digits.count == 6
            && digits.allSatisfy(\.isHexDigit)
    }

    var glyph: Icon.Glyph? {
        if case let .glyph(glyph) = mark {
            glyph
        } else {
            nil
        }
    }

    var emoji: String? {
        if case let .emoji(value) = mark {
            value.trimmed
        } else {
            nil
        }
    }

    var text: String? {
        if case let .text(value) = mark {
            value.trimmed
        } else {
            nil
        }
    }
}
