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

    func paletteUpdates() -> some AsyncSequence<ThemePalette, any Error> {
        ValueObservation
            .tracking(Self.palette)
            .removeDuplicates()
            .values(in: writer)
    }

    func palette() async throws -> ThemePalette {
        try await writer.read(Self.palette)
    }
}

private extension AppDatabase {
    static func customThemes(in db: Database) throws -> [Theme] {
        try Theme
            .filter(Column("is_builtin") == false)
            .order(Column("created_at"))
            .fetchAll(db)
    }

    static func palette(in db: Database) throws -> ThemePalette {
        switch try setting(.theme, in: db) {
        case let .preset(preset):
            return preset.palette
        case let .custom(id):
            let theme = try Theme.fetchOne(db, key: id)
            return theme?.palette ?? .night
        }
    }
}
