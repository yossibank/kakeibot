import Core
import Foundation
import GRDB

public struct AppDatabase: Sendable {
    let writer: any DatabaseWriter
    let entryListObservation: SharedValueObservation<EntryList>

    init(_ writer: any DatabaseWriter) throws {
        try Self.migrator.migrate(writer)
        self.init(migrated: writer)
    }
}

public extension AppDatabase {
    enum SetupError: Error {
        case appGroupUnavailable
        case notMigrated
    }
}

public extension AppDatabase {
    static func appGroup() throws -> AppDatabase {
        let path = try groupPath()
        let pool = try DatabasePool(path: path, configuration: configuration)
        let database = try AppDatabase(pool)
        let now = Date()

        try database.insertDefaultsIfEmpty(at: now)
        try database.insertShelfIfEmpty(at: now)
        try database.returnSharedCategoriesOfUnsharedWallets()

        return database
    }

    static func appGroupForReading() throws -> AppDatabase {
        try appGroupMigrated(readonly: true)
    }

    static func appGroupForWriting() throws -> AppDatabase {
        try appGroupMigrated(readonly: false)
    }

    static func inMemory() throws -> AppDatabase {
        let queue = try DatabaseQueue(configuration: configuration)

        guard let migratedTemplate else {
            return try AppDatabase(queue)
        }

        try migratedTemplate.backup(to: queue)

        return AppDatabase(migrated: queue)
    }

    static func suspend() {
        NotificationCenter.default.post(name: Database.suspendNotification, object: nil)
    }

    static func resume() {
        NotificationCenter.default.post(name: Database.resumeNotification, object: nil)
    }

    func reloadAfterOtherProcesses() async throws {
        try await writer.write { db in
            try db.notifyChanges(in: .fullDatabase)
        }
    }
}

extension AppDatabase {
    static var migrator: DatabaseMigrator {
        var migrator = DatabaseMigrator()

        for (name, migrate) in migrations {
            migrator.registerMigration(name, migrate: migrate)
        }

        return migrator
    }
}

private extension AppDatabase {
    static let groupIdentifier = "group.com.yossibank.kakeibot"
    static let fileName = "kakeibot.sqlite"
    static let busyTimeout: TimeInterval = 5
    static let migratedTemplate = try? makeMigratedTemplate()

    static var migrations: [(String, @Sendable (Database) throws -> Void)] {
        [
            ("v1", MigrationV001.migrate),
            ("v2", MigrationV002.migrate),
            ("v3", MigrationV003.migrate),
            ("v4", MigrationV004.migrate),
            ("v5", MigrationV005.migrate),
            ("v6", MigrationV006.migrate),
            ("v7", MigrationV007.migrate),
            ("v8", MigrationV008.migrate),
            ("v9", MigrationV009.migrate),
            ("v10", MigrationV010.migrate),
            ("v11", MigrationV011.migrate),
            ("v12", MigrationV012.migrate),
            ("v13", MigrationV013.migrate),
            ("v15", MigrationV015.migrate),
            ("v16", MigrationV016.migrate),
            ("v17", MigrationV017.migrate),
            ("v18", MigrationV018.migrate),
            ("v19", MigrationV019.migrate),
            ("v20", MigrationV020.migrate),
            ("v21", MigrationV021.migrate),
            ("v22", MigrationV022.migrate),
            ("v23", MigrationV023.migrate),
            ("v24", MigrationV024.migrate),
            ("v25", MigrationV025.migrate),
            ("v26", MigrationV026.migrate),
            ("v27", MigrationV027.migrate),
            ("v28", MigrationV028.migrate),
            ("v29", MigrationV029.migrate),
            ("v30", MigrationV030.migrate),
            ("v31", MigrationV031.migrate),
            ("v32", MigrationV032.migrate),
            ("v33", MigrationV033.migrate),
            ("v34", MigrationV034.migrate),
            ("v35", MigrationV035.migrate),
            ("v36", MigrationV036.migrate),
            ("v37", MigrationV037.migrate),
            ("v38", MigrationV038.migrate),
            ("v39", MigrationV039.migrate),
            ("v40", MigrationV040.migrate),
            ("v41", MigrationV041.migrate),
            ("v42", MigrationV042.migrate),
            ("v43", MigrationV043.migrate),
            ("v44", MigrationV044.migrate)
        ]
    }

    static var groupContainer: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: groupIdentifier)
    }

    static var configuration: Configuration {
        var configuration = Configuration()

        configuration.observesSuspensionNotifications = true
        configuration.persistentReadOnlyConnections = true
        configuration.busyMode = .timeout(busyTimeout)

        return configuration
    }

    init(migrated writer: any DatabaseWriter) {
        self.writer = writer

        self.entryListObservation = ValueObservation
            .tracking { db in
                try Self.entryList(in: db)
            }
            .removeDuplicates()
            .shared(in: writer)
    }

    static func makeMigratedTemplate() throws -> DatabaseQueue {
        let queue = try DatabaseQueue()
        try migrator.migrate(queue)
        return queue
    }

    static func appGroupMigrated(readonly: Bool) throws -> AppDatabase {
        var configuration = configuration

        configuration.readonly = readonly

        let path = try groupPath()
        let pool = try DatabasePool(path: path, configuration: configuration)

        let isMigrated = try pool.read { db in
            try migrator.hasCompletedMigrations(db)
        }

        guard isMigrated else {
            throw SetupError.notMigrated
        }

        return AppDatabase(migrated: pool)
    }

    static func groupPath() throws -> String {
        guard let directory = groupContainer else {
            throw SetupError.appGroupUnavailable
        }

        return directory.appending(path: fileName).path(percentEncoded: false)
    }
}
