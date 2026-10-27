import Core
import Features
import Foundation
import Store
import Testing

@MainActor
struct BackupModelTests {
    @Test
    func namesFileByDay() async throws {
        let setup = try Setup()
        let model = BackupModel(database: setup.source, stash: setup.stash, appVersion: "1.2")

        let isMade = await model.makeFile(.json, at: setup.now)
        let file = try #require(model.file)
        let export = try ExportV1(json: file.data)

        #expect(isMade)
        #expect(file.name == "kakeibot-2026-10-03.json")
        #expect(export.app == ExportV1.App(platform: .ios, version: "1.2"))
    }

    @Test
    func writesSpreadsheet() async throws {
        let setup = try Setup()
        let model = BackupModel(database: setup.source, stash: setup.stash)

        await model.makeFile(.csv, at: setup.now)
        let file = try #require(model.file)
        let text = String(decoding: file.data, as: UTF8.self)

        #expect(file.name == "kakeibot-2026-10-03.csv")
        #expect(text == "\u{FEFF}日付,種類,金額,カテゴリ,タグ,財布,振替先,メモ\r\n")
    }

    @Test
    func restoresAfterConfirming() async throws {
        let setup = try Setup()
        let source = BackupModel(database: setup.source, stash: setup.stash)
        let target = BackupModel(database: setup.target, stash: setup.stash)
        await source.makeFile(.json, at: setup.now)
        let file = try #require(source.file)

        let isRead = target.read(file.data)
        let summary = target.pendingSummary
        await target.restore()

        #expect(isRead)
        #expect(summary == "2026/10/3 に書き出した記録 0 件・口座 2 件に置き換えます。いまのデータは残りません")
        #expect(target.pending == nil)
        #expect(target.doneMessage == "読み込みました")
        #expect(try setup.target.snapshot() == setup.source.snapshot())
    }

    @Test
    func keepsDataWhenCancelled() async throws {
        let setup = try Setup()
        let source = BackupModel(database: setup.source, stash: setup.stash)
        let target = BackupModel(database: setup.target, stash: setup.stash)
        await source.makeFile(.json, at: setup.now)
        let file = try #require(source.file)

        target.read(file.data)
        target.cancelRestore()
        await target.restore()

        #expect(target.pending == nil)
        #expect(try setup.target.snapshot().wallets.isEmpty)
    }

    @Test
    func stashesCurrentDataBeforeRestoring() async throws {
        let setup = try Setup()
        let source = BackupModel(database: setup.source, stash: setup.stash)
        let target = BackupModel(database: setup.target, stash: setup.stash)
        try setup.target.insertDefaultsIfEmpty(at: setup.now)
        let before = try setup.target.snapshot()
        await source.makeFile(.json, at: setup.now)
        let file = try #require(source.file)

        target.read(file.data)
        await target.restore()
        let stashed = try #require(setup.stash.load().first)
        let export = try ExportV1(json: stashed.data)

        #expect(export.data == before)
        #expect(target.previous.count == 1)
    }

    @Test
    func keepsDataWhenStashFails() async throws {
        let setup = try Setup()
        let blocker = URL.temporaryDirectory.appending(path: UUID().uuidString)
        try Data().write(to: blocker)
        let stash = BackupStash(urls: [blocker.appending(path: "previous.json")])
        let source = BackupModel(database: setup.source, stash: setup.stash)
        let target = BackupModel(database: setup.target, stash: stash)
        await source.makeFile(.json, at: setup.now)
        let file = try #require(source.file)

        target.read(file.data)
        await target.restore()

        #expect(target.errorNotice.message == "読み込めませんでした。いまのデータはそのままです")
        #expect(try setup.target.snapshot().wallets.isEmpty)
        #expect(target.previous.isEmpty)
    }

    @Test
    func readsStashedDataToGoBack() async throws {
        let setup = try Setup()
        let source = BackupModel(database: setup.source, stash: setup.stash)
        let target = BackupModel(database: setup.target, stash: setup.stash)
        try setup.target.insertDefaultsIfEmpty(at: setup.now)
        let before = try setup.target.snapshot()
        await source.makeFile(.json, at: setup.now)
        let file = try #require(source.file)

        target.read(file.data)
        await target.restore()
        let isRead = await target.readPrevious(target.previous[0])
        await target.restore()

        #expect(isRead)
        #expect(try setup.target.snapshot().wallets.count == before.wallets.count)
    }

    @Test
    func goesBackToFirstDataAfterTwoRestores() async throws {
        let setup = try Setup()
        let target = BackupModel(database: setup.target, stash: setup.stash)
        try setup.target.insertDefaultsIfEmpty(at: setup.now)
        let first = try setup.target.snapshot()

        try await restore(target, from: setup.source, now: setup.now)
        let second = try setup.target.snapshot()
        try await restore(target, from: AppDatabase.inMemory(defaultsAt: setup.now), now: setup.now)
        let isRead = await target.readPrevious(target.previous[1])
        await target.restore()

        #expect(isRead)
        #expect(second != first)
        #expect(target.previous.count == 2)
        #expect(try setup.target.snapshot() == first)
    }

    @Test
    func dropsOldestStashAfterThreeRestores() async throws {
        let setup = try Setup()
        let target = BackupModel(database: setup.target, stash: setup.stash)
        try setup.target.insertDefaultsIfEmpty(at: setup.now)
        let first = try setup.target.snapshot()

        for _ in 0..<3 {
            let source = try AppDatabase.inMemory(defaultsAt: setup.now)
            try await restore(target, from: source, now: setup.now)
        }

        let tables = try setup.stash.load().map { try ExportV1(json: $0.data).data }

        #expect(tables.count == 2)
        #expect(!tables.contains(first))
        #expect(target.previous.count == 2)
    }

    @Test
    func skipsBrokenStashRow() async throws {
        let setup = try Setup()
        let model = BackupModel(database: setup.target, stash: setup.stash)
        let app = ExportV1.App(platform: .ios, version: "1.0")
        let valid = try await setup.source.backup(at: setup.now, app: app)

        try Data("x".utf8).write(to: setup.stash.urls[0])
        try valid.write(to: setup.stash.urls[1])
        await model.loadPrevious()
        let item = try #require(model.previous.first)
        let isRead = await model.readPrevious(item)

        #expect(model.previous.count == 1)
        #expect(item.url == setup.stash.urls[1])
        #expect(isRead)
        #expect(model.pending?.exportedAt == setup.now)
    }

    @Test
    func keepsRowForSecondStashWhenFirstIsMissing() async throws {
        let setup = try Setup()
        let model = BackupModel(database: setup.target, stash: setup.stash)
        let app = ExportV1.App(platform: .ios, version: "1.0")
        let valid = try await setup.source.backup(at: setup.now, app: app)

        try valid.write(to: setup.stash.urls[1])
        await model.loadPrevious()
        let item = try #require(model.previous.first)
        let isRead = await model.readPrevious(item)

        #expect(model.previous.count == 1)
        #expect(isRead)
    }

    @Test
    func keepsBothGenerationsWhenSaveFails() throws {
        let setup = try Setup()
        let first = Data("first".utf8)
        let second = Data("second".utf8)

        try first.write(to: setup.stash.urls[0])
        try second.write(to: setup.stash.urls[1])

        for failing in 1...2 {
            let counter = Counter()
            let stash = BackupStash(urls: setup.stash.urls) { data, url in
                if counter.next() == failing {
                    throw CocoaError(.fileWriteUnknown)
                }

                try data.write(to: url, options: .atomic)
            }

            #expect(throws: CocoaError.self) {
                try stash.save(Data("new".utf8))
            }

            #expect(try Data(contentsOf: setup.stash.urls[0]) == first)
            #expect(try Data(contentsOf: setup.stash.urls[1]) == second)
        }
    }

    @Test
    func rejectsOtherFiles() throws {
        let setup = try Setup()
        let model = BackupModel(database: setup.target, stash: setup.stash)
        let other = Data(#"{"format":"other","version":1}"#.utf8)
        let newer = Data(#"{"format":"kakeibot-export","version":99}"#.utf8)

        #expect(!model.read(other))
        #expect(model.errorNotice.message == "かけいぼっとのバックアップではありません")

        #expect(!model.read(newer))
        #expect(model.errorNotice.message == "新しい版のアプリで書き出したファイルです")

        #expect(!model.read(Data("x".utf8)))
        #expect(model.errorNotice.message == "ファイルを読めませんでした")
    }
}

extension BackupModelTests {
    final class Counter: @unchecked Sendable {
        private var count = 0

        func next() -> Int {
            count += 1
            return count
        }
    }

    struct Setup {
        let source: AppDatabase
        let target: AppDatabase
        let now: Date
        let stash: BackupStash
    }

    func restore(
        _ model: BackupModel,
        from source: AppDatabase,
        now: Date
    ) async throws {
        let app = ExportV1.App(platform: .ios, version: "1.0")
        let data = try await source.backup(at: now, app: app)

        model.read(data)
        await model.restore()
    }
}

extension BackupModelTests.Setup {
    init() throws {
        let source = try AppDatabase.inMemory()
        let target = try AppDatabase.inMemory()
        let now = try #require(Self.date("2026-10-03T12:00:00"))
        try source.insertDefaultsIfEmpty(at: now)

        let url = URL.temporaryDirectory
            .appending(path: UUID().uuidString)
            .appending(path: "previous.json")

        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )

        self.init(
            source: source,
            target: target,
            now: now,
            stash: BackupStash(
                urls: [
                    url,
                    url.deletingLastPathComponent().appending(path: "previous-2.json")
                ]
            )
        )
    }

    static func date(_ text: String) -> Date? {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        return formatter.date(from: text)
    }
}

private extension AppDatabase {
    static func inMemory(defaultsAt date: Date) throws -> AppDatabase {
        let database = try AppDatabase.inMemory()
        try database.insertDefaultsIfEmpty(at: date)
        return database
    }
}
