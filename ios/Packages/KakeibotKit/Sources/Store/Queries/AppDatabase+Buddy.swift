import Core
import GRDB

public extension AppDatabase {
    func buddyProfile() async throws -> BuddyProfile {
        try await writer.read { db in
            try Self.buddyProfile(in: db)
        }
    }

    func buddyProfileUpdates() -> some AsyncSequence<BuddyProfile, any Error> {
        ValueObservation
            .tracking { db in
                try Self.buddyProfile(in: db)
            }
            .removeDuplicates()
            .values(in: writer)
    }
}

private extension AppDatabase {
    static func buddyProfile(in db: Database) throws -> BuddyProfile {
        try BuddyProfile(
            buddy: setting(.buddy, in: db),
            customName: setting(.buddyName, in: db)
        )
    }
}
