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
        let model = BackupModel(database: setup.source, appVersion: "1.2")

        let isMade = await model.makeFile(at: setup.now)
        let file = try #require(model.file)
        let export = try ExportV1(json: file.data)

        #expect(isMade)
        #expect(file.name == "kakeibot-2026-10-03.json")
        #expect(export.app == ExportV1.App(platform: .ios, version: "1.2"))
    }

    @Test
    func restoresAfterConfirming() async throws {
        let setup = try Setup()
        let source = BackupModel(database: setup.source)
        let target = BackupModel(database: setup.target)
        await source.makeFile(at: setup.now)
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
        let source = BackupModel(database: setup.source)
        let target = BackupModel(database: setup.target)
        await source.makeFile(at: setup.now)
        let file = try #require(source.file)

        target.read(file.data)
        target.cancelRestore()
        await target.restore()

        #expect(target.pending == nil)
        #expect(try setup.target.snapshot().wallets.isEmpty)
    }

    @Test
    func rejectsOtherFiles() throws {
        let setup = try Setup()
        let model = BackupModel(database: setup.target)
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
    struct Setup {
        let source: AppDatabase
        let target: AppDatabase
        let now: Date
    }
}

extension BackupModelTests.Setup {
    init() throws {
        let source = try AppDatabase.inMemory()
        let target = try AppDatabase.inMemory()
        let now = try #require(Self.date("2026-10-03T12:00:00"))
        try source.insertDefaultsIfEmpty(at: now)

        self.init(source: source, target: target, now: now)
    }

    static func date(_ text: String) -> Date? {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        return formatter.date(from: text)
    }
}
