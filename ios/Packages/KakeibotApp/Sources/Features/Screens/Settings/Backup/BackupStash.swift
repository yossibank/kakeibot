import Foundation

public struct BackupStash: Sendable {
    public let urls: [URL]

    public init(urls: [URL]) {
        self.urls = urls
    }
}

public extension BackupStash {
    static var standard: BackupStash {
        let base = URL.applicationSupportDirectory

        return BackupStash(
            urls: [
                base.appending(path: "kakeibot-previous.json"),
                base.appending(path: "kakeibot-previous-2.json")
            ]
        )
    }

    func load() -> [Data] {
        urls.compactMap { try? Data(contentsOf: $0) }
    }

    func save(_ data: Data) throws {
        guard let newest = urls.first else {
            return
        }

        let manager = FileManager.default
        let directory = newest.deletingLastPathComponent()
        let pending = directory.appending(path: UUID().uuidString)

        try manager.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )
        try data.write(to: pending, options: .atomic)

        for index in urls.indices.dropFirst().reversed() {
            try move(from: urls[index - 1], to: urls[index])
        }

        try move(from: pending, to: newest)
    }
}

private extension BackupStash {
    func move(from source: URL, to destination: URL) throws {
        let manager = FileManager.default

        guard manager.fileExists(atPath: source.path) else {
            return
        }

        if manager.fileExists(atPath: destination.path) {
            try manager.removeItem(at: destination)
        }

        try manager.moveItem(at: source, to: destination)
    }
}
