import Foundation

public struct IconDraft: Hashable, Sendable {
    public var mark: Mark
    public var color: String

    public init(
        mark: Mark,
        color: String
    ) {
        self.mark = mark
        self.color = color
    }
}

public extension IconDraft {
    enum Mark: Hashable, Sendable {
        case glyph(Icon.Glyph)
        case emoji(String)
        case text(String)
    }

    static let maxTextLength = 3

    var problems: [DraftProblem] {
        let colorProblems: [DraftProblem] = isValidColor ? [] : [.invalidColor]
        return markProblems + colorProblems
    }

    init(_ icon: Icon) {
        self.init(mark: Mark(icon), color: icon.color)
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

public extension IconDraft.Mark {
    init(_ icon: Icon) {
        if let glyph = icon.glyph {
            self = .glyph(glyph)
        } else if let emoji = icon.emoji, !emoji.isEmpty {
            self = .emoji(emoji)
        } else {
            self = .text(icon.text ?? "")
        }
    }
}

private extension IconDraft {
    var markProblems: [DraftProblem] {
        switch mark {
        case .glyph:
            return []
        case let .emoji(value):
            return Self.trimmed(value).isEmpty ? [.emptyMark] : []
        case let .text(value):
            let trimmed = Self.trimmed(value)

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
            Self.trimmed(value)
        } else {
            nil
        }
    }

    var text: String? {
        if case let .text(value) = mark {
            Self.trimmed(value)
        } else {
            nil
        }
    }

    static func trimmed(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func validate() throws {
        if let problem = problems.first {
            throw problem
        }
    }
}
