import Core
import Features
import Foundation
import Store
import Testing

extension BackupModelTests {
    final class Counter: @unchecked Sendable {
        private var count = 0
    }

    struct Setup {
        let source: AppDatabase
        let target: AppDatabase
        let now: Date
        let stash: BackupStash
    }
}

extension BackupModelTests.Counter {
    func next() -> Int {
        count += 1
        return count
    }
}

extension BackupModelTests.Setup {
    init() throws {
        let source = try AppDatabase.inMemory()
        let target = try AppDatabase.inMemory()
        let now = try #require(Self.date("2026-10-03T12:00:00"))

        let url = URL.temporaryDirectory
            .appending(path: UUID().uuidString)
            .appending(path: "previous.json")

        let directory = url.deletingLastPathComponent()
        let secondURL = directory.appending(path: "previous-2.json")
        let stash = BackupStash(urls: [url, secondURL])

        try source.insertDefaultsIfEmpty(at: now)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        self.init(source: source, target: target, now: now, stash: stash)
    }

    static func date(_ text: String) -> Date? {
        let formatter = DateFormatter()

        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"

        return formatter.date(from: text)
    }
}
