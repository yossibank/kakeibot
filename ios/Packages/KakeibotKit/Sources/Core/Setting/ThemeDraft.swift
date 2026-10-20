import Foundation

public struct ThemeDraft: Hashable, Sendable {
    public var name: String
    public var background: String
    public var surface: String
    public var text: String
    public var subtext: String
    public var accent: String
    public var style: ThemeStyle

    public init(
        name: String,
        background: String,
        surface: String,
        text: String,
        subtext: String,
        accent: String,
        style: ThemeStyle = .standard
    ) {
        self.name = name
        self.background = background
        self.surface = surface
        self.text = text
        self.subtext = subtext
        self.accent = accent
        self.style = style
    }
}

public extension ThemeDraft {
    typealias Problem = DraftProblem

    static let maxNameLength = 12

    var palette: ThemePalette? {
        let colors = [background, surface, text, subtext, accent]
            .compactMap(ThemeHex.rgb)

        guard colors.count == 5 else {
            return nil
        }

        return ThemePalette(
            background: colors[0],
            surface: colors[1],
            text: colors[2],
            subtext: colors[3],
            accent: colors[4]
        )
    }

    var problems: [Problem] {
        guard let palette else {
            return nameProblems + [.invalidColor]
        }

        let isReadable = palette.unreadableRoles.isEmpty
        return nameProblems + (isReadable ? [] : [.unreadableColors])
    }

    init(
        name: String,
        palette: ThemePalette,
        style: ThemeStyle = .standard
    ) {
        self.init(
            name: name,
            background: ThemeHex.text(palette.backgroundTop),
            surface: ThemeHex.text(palette.cardTop),
            text: ThemeHex.text(palette.text),
            subtext: ThemeHex.text(palette.subtext),
            accent: ThemeHex.text(palette.accent),
            style: style
        )
    }

    init(_ theme: Theme) {
        self.init(
            name: theme.name,
            background: theme.background,
            surface: theme.surface,
            text: theme.textPrimary,
            subtext: theme.textSecondary,
            accent: theme.accent,
            style: theme.style
        )
    }

    func newTheme(at now: Date) throws -> Theme {
        try validate()

        return Theme(
            name: trimmedName,
            background: background,
            surface: surface,
            textPrimary: text,
            textSecondary: subtext,
            accent: accent,
            expense: Self.expenseColor,
            income: accent,
            cornerRadius: style.corner.rawValue,
            fontId: style.font.rawValue,
            isBuiltin: false,
            createdAt: now,
            updatedAt: now
        )
    }

    func applied(
        to theme: Theme,
        at now: Date
    ) throws -> Theme {
        try validate()

        var updated = theme
        updated.name = trimmedName
        updated.background = background
        updated.surface = surface
        updated.textPrimary = text
        updated.textSecondary = subtext
        updated.accent = accent
        updated.income = accent
        updated.cornerRadius = style.corner.rawValue
        updated.fontId = style.font.rawValue
        updated.updatedAt = now
        return updated
    }
}

private extension ThemeDraft {
    static let expenseColor = "#E3A3A3"

    var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var nameProblems: [Problem] {
        if trimmedName.isEmpty {
            [.emptyName]
        } else if trimmedName.count > Self.maxNameLength {
            [.nameTooLong]
        } else {
            []
        }
    }

    func validate() throws {
        if let problem = problems.first {
            throw problem
        }
    }
}
