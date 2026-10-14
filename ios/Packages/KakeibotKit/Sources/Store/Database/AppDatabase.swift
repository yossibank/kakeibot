import Foundation
import GRDB

public struct AppDatabase: Sendable {
    public let writer: any DatabaseWriter

    public init(_ writer: any DatabaseWriter) throws {
        self.writer = writer
        try Self.migrator.migrate(writer)
    }
}

public extension AppDatabase {
    enum SetupError: Error {
        case appGroupUnavailable
    }

    static func appGroup() throws -> AppDatabase {
        guard let directory = groupContainer else {
            throw SetupError.appGroupUnavailable
        }

        let url = directory.appending(path: fileName)
        let path = url.path(percentEncoded: false)
        let pool = try DatabasePool(path: path, configuration: configuration)
        let database = try AppDatabase(pool)
        try database.insertDefaultsIfEmpty(at: Date())
        return database
    }

    static func inMemory() throws -> AppDatabase {
        let queue = try DatabaseQueue(configuration: configuration)
        return try AppDatabase(queue)
    }

    static func suspend() {
        NotificationCenter.default.post(
            name: Database.suspendNotification,
            object: nil
        )
    }

    static func resume() {
        NotificationCenter.default.post(
            name: Database.resumeNotification,
            object: nil
        )
    }
}

extension AppDatabase {
    static var migrator: DatabaseMigrator {
        var migrator = DatabaseMigrator()
        migrator.registerMigration("v1", migrate: MigrationV1.migrate)
        migrator.registerMigration("v2", migrate: MigrationV2.migrate)
        migrator.registerMigration("v3", migrate: MigrationV3.migrate)
        migrator.registerMigration("v4", migrate: MigrationV4.migrate)
        return migrator
    }
}

private extension AppDatabase {
    static let groupIdentifier = "group.com.yossibank.kakeibot"
    static let fileName = "kakeibot.sqlite"

    static var groupContainer: URL? {
        let manager = FileManager.default

        return manager.containerURL(
            forSecurityApplicationGroupIdentifier: groupIdentifier
        )
    }

    static var configuration: Configuration {
        var configuration = Configuration()
        configuration.observesSuspensionNotifications = true
        return configuration
    }
}
