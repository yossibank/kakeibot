import Foundation

public struct BackupStash: Sendable {
    public let url: URL

    public init(url: URL) {
        self.url = url
    }
}

public extension BackupStash {
    static var standard: BackupStash {
        let base = URL.applicationSupportDirectory

        return BackupStash(url: base.appending(path: "kakeibot-previous.json"))
    }

    func load() -> Data? {
        try? Data(contentsOf: url)
    }

    func save(_ data: Data) throws {
        let directory = url.deletingLastPathComponent()

        try FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )
        try data.write(to: url, options: .atomic)
    }
}
