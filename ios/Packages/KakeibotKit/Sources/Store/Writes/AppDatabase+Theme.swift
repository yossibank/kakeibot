import Core
import Foundation
import GRDB

public extension AppDatabase {
    enum ThemeWriteError: Error, Equatable {
        case themeNotFound
    }

    @discardableResult
    func saveTheme(
        _ draft: ThemeDraft,
        editing id: Theme.ID? = nil,
        at now: Date
    ) async throws -> Theme {
        try await writer.write { db in
            guard let id else {
                let theme = try draft.newTheme(at: now)

                try theme.insert(db)

                return theme
            }

            guard let theme = try Theme.fetchOne(db, key: id) else {
                throw ThemeWriteError.themeNotFound
            }

            let updated = try draft.applied(to: theme, at: now)

            try updated.update(db)

            return updated
        }
    }

    @discardableResult
    func deleteTheme(_ id: Theme.ID) async throws -> Deletion {
        try await writer.write { db in
            guard let theme = try Theme.fetchOne(db, key: id) else {
                throw ThemeWriteError.themeNotFound
            }

            try theme.delete(db)

            let choice = try Self.setting(.theme, in: db)

            guard choice == .custom(id) else {
                return Deletion(themes: [theme])
            }

            try Self.setSetting(.theme, to: .preset(.white), in: db)

            return Deletion(themes: [theme], themeChoice: choice)
        }
    }
}
