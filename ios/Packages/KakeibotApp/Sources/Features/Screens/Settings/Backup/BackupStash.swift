import Foundation

public struct BackupStash: Sendable {
    public typealias Write = @Sendable (Data, URL) throws -> Void

    public struct Item: Sendable {
        public let url: URL
        public let data: Data
    }

    public let urls: [URL]

    private let write: Write

    public init(
        urls: [URL],
        write: @escaping Write = { try $0.write(to: $1, options: .atomic) }
    ) {
        self.urls = urls
        self.write = write
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

    func load() -> [Item] {
        urls.compactMap { url in
            (try? Data(contentsOf: url)).map { Item(url: url, data: $0) }
        }
    }

    func save(_ data: Data) throws {
        guard let newest = urls.first else {
            return
        }

        try FileManager.default.createDirectory(
            at: newest.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )

        let originals = urls.map { try? Data(contentsOf: $0) }

        do {
            try write(data, newest)

            for index in urls.indices.dropFirst() {
                if let previous = originals[index - 1] {
                    try write(previous, urls[index])
                }
            }
        } catch {
            restore(originals)
            throw error
        }
    }
}

private extension BackupStash {
    func restore(_ originals: [Data?]) {
        for (url, original) in zip(urls, originals) {
            if let original {
                try? original.write(to: url, options: .atomic)
            } else {
                try? FileManager.default.removeItem(at: url)
            }
        }
    }
}
