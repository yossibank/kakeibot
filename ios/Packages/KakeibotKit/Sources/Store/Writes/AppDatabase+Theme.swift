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

    func deleteTheme(_ id: Theme.ID) async throws {
        try await writer.write { db in
            guard try Theme.deleteOne(db, key: id) else {
                throw ThemeWriteError.themeNotFound
            }

            let choice = try Self.setting(.theme, in: db)

            if choice == .custom(id) {
                try Self.setSetting(.theme, to: .preset(.white), in: db)
            }
        }
    }
}
