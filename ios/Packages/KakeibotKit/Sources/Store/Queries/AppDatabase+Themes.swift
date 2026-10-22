import Core
import GRDB

public extension AppDatabase {
    func customThemeUpdates() -> some AsyncSequence<[Theme], any Error> {
        ValueObservation
            .tracking(Self.customThemes)
            .values(in: writer)
    }

    func customThemes() async throws -> [Theme] {
        try await writer.read(Self.customThemes)
    }

    func themeLookUpdates() -> some AsyncSequence<ThemeLook, any Error> {
        ValueObservation
            .tracking(Self.themeLook)
            .removeDuplicates()
            .values(in: writer)
    }

    func themeLook() async throws -> ThemeLook {
        try await writer.read(Self.themeLook)
    }

    func styleUpdates() -> some AsyncSequence<ThemeStyle, any Error> {
        ValueObservation
            .tracking(Self.style)
            .removeDuplicates()
            .values(in: writer)
    }

    func style() async throws -> ThemeStyle {
        try await writer.read(Self.style)
    }
}

private extension AppDatabase {
    static func customThemes(in db: Database) throws -> [Theme] {
        try Theme
            .filter(Column("is_builtin") == false)
            .order(Column("created_at"))
            .fetchAll(db)
    }

    static func themeLook(in db: Database) throws -> ThemeLook {
        switch try setting(.theme, in: db) {
        case .system:
            return .followsDevice
        case let .preset(preset):
            return .fixed(preset.palette)
        case let .custom(id):
            let theme = try Theme.fetchOne(db, key: id)
            let palette = theme?.palette
            return palette.map(ThemeLook.fixed) ?? .followsDevice
        }
    }

    static func style(in db: Database) throws -> ThemeStyle {
        try ThemeStyle(
            corner: setting(.cornerStyle, in: db),
            displayFont: setting(.fontStyle, in: db),
            textFont: setting(.textFontStyle, in: db),
            textSize: setting(.textSize, in: db)
        )
    }
}
