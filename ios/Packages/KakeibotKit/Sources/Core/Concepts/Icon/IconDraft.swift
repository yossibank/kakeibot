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
        self.init(mark: icon.mark, color: icon.color)
    }
}

public extension IconDraft {
    typealias Mark = Icon.Mark

    static let maxTextLength = 3

    var problems: [DraftProblem] {
        let colorProblems: [DraftProblem] = isValidColor ? [] : [.invalidColor]
        return markProblems + colorProblems
    }

    func newIcon(at now: Date) throws -> Icon {
        let blank = Icon(emoji: nil, text: nil, color: color, createdAt: now, updatedAt: now)
        return try applied(to: blank, at: now)
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
        ThemeHex.rgb(color) != nil
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
