import GRDB

public extension AppDatabase {
    static func isStorageFull(_ error: any Error) -> Bool {
        (error as? DatabaseError)?.resultCode == .SQLITE_FULL
    }
}
