import Foundation
import GRDB

public struct AppDatabase: Sendable {
    public let writer: any DatabaseWriter

    let entryListObservation: SharedValueObservation<EntryList>

    public init(_ writer: any DatabaseWriter) throws {
        try Self.migrator.migrate(writer)
        self.init(migrated: writer)
    }
}

public extension AppDatabase {
    enum SetupError: Error {
        case appGroupUnavailable
        case notMigrated
    }

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
        return try AppDatabase(queue)
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

        migrator.registerMigration("v1", migrate: MigrationV001.migrate)
        migrator.registerMigration("v2", migrate: MigrationV002.migrate)
        migrator.registerMigration("v3", migrate: MigrationV003.migrate)
        migrator.registerMigration("v4", migrate: MigrationV004.migrate)
        migrator.registerMigration("v5", migrate: MigrationV005.migrate)
        migrator.registerMigration("v6", migrate: MigrationV006.migrate)
        migrator.registerMigration("v7", migrate: MigrationV007.migrate)
        migrator.registerMigration("v8", migrate: MigrationV008.migrate)
        migrator.registerMigration("v9", migrate: MigrationV009.migrate)
        migrator.registerMigration("v10", migrate: MigrationV010.migrate)
        migrator.registerMigration("v11", migrate: MigrationV011.migrate)
        migrator.registerMigration("v12", migrate: MigrationV012.migrate)
        migrator.registerMigration("v13", migrate: MigrationV013.migrate)
        migrator.registerMigration("v15", migrate: MigrationV015.migrate)
        migrator.registerMigration("v16", migrate: MigrationV016.migrate)
        migrator.registerMigration("v17", migrate: MigrationV017.migrate)
        migrator.registerMigration("v18", migrate: MigrationV018.migrate)
        migrator.registerMigration("v19", migrate: MigrationV019.migrate)
        migrator.registerMigration("v20", migrate: MigrationV020.migrate)
        migrator.registerMigration("v21", migrate: MigrationV021.migrate)
        migrator.registerMigration("v22", migrate: MigrationV022.migrate)
        migrator.registerMigration("v23", migrate: MigrationV023.migrate)
        migrator.registerMigration("v24", migrate: MigrationV024.migrate)
        migrator.registerMigration("v25", migrate: MigrationV025.migrate)
        migrator.registerMigration("v26", migrate: MigrationV026.migrate)
        migrator.registerMigration("v27", migrate: MigrationV027.migrate)
        migrator.registerMigration("v28", migrate: MigrationV028.migrate)
        migrator.registerMigration("v29", migrate: MigrationV029.migrate)
        migrator.registerMigration("v30", migrate: MigrationV030.migrate)
        migrator.registerMigration("v31", migrate: MigrationV031.migrate)
        migrator.registerMigration("v32", migrate: MigrationV032.migrate)
        migrator.registerMigration("v33", migrate: MigrationV033.migrate)
        migrator.registerMigration("v34", migrate: MigrationV034.migrate)
        migrator.registerMigration("v35", migrate: MigrationV035.migrate)
        migrator.registerMigration("v36", migrate: MigrationV036.migrate)
        migrator.registerMigration("v37", migrate: MigrationV037.migrate)
        migrator.registerMigration("v38", migrate: MigrationV038.migrate)

        return migrator
    }
}

private extension AppDatabase {
    static let groupIdentifier = "group.com.yossibank.kakeibot"
    static let fileName = "kakeibot.sqlite"
    static let busyTimeout: TimeInterval = 5

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
