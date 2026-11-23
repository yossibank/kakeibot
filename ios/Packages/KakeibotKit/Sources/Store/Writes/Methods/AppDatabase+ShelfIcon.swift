import Core
import Foundation
import GRDB

public extension AppDatabase {
    enum ShelfIconWriteError: Error, Equatable {
        case shelfIconNotFound
        case iconNotFound
    }

    @discardableResult
    func deleteShelfIcon(_ id: ShelfIcon.ID) async throws -> Deletion {
        try await writer.write { db in
            guard let shelfIcon = try ShelfIcon.fetchOne(db, key: id) else {
                throw ShelfIconWriteError.shelfIconNotFound
            }

            try shelfIcon.delete(db)

            return Deletion(shelfIcons: [shelfIcon])
        }
    }
}
