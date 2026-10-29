import GRDB

public extension AppDatabase {
    static func isInterrupted(_ error: any Error) -> Bool {
        (error as? DatabaseError)?.isInterruptionError == true
    }
}
