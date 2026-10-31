import Features
import Foundation
import Store
import Testing

extension BackupModelTests {
    @Test
    func keepsExportAgeHiddenUnderOneMonth() {
        let calendar = Self.calendar
        let exported = Self.date(2026, 1, 15, calendar)

        let none = BackupModel.exportAgeText(exportedAt: nil, now: exported, calendar: calendar)
        let same = BackupModel.exportAgeText(
            exportedAt: exported,
            now: exported,
            calendar: calendar
        )
        let almost = BackupModel.exportAgeText(
            exportedAt: exported,
            now: Self.date(2026, 2, 14, calendar),
            calendar: calendar
        )

        #expect(none == nil)
        #expect(same == nil)
        #expect(almost == nil)
    }

    @Test
    func tellsNotExportedAfterOneMonthOfRecords() {
        let calendar = Self.calendar
        let first = Self.date(2026, 1, 15, calendar)

        func text(_ month: Int, _ day: Int) -> String? {
            BackupModel.exportAgeText(
                exportedAt: nil,
                firstCreatedAt: first,
                now: Self.date(2026, month, day, calendar),
                calendar: calendar
            )
        }

        #expect(text(2, 14) == nil)
        #expect(text(2, 15) == "未")
    }

    @Test
    func tellsExportAgeInMonthsThenYears() {
        let calendar = Self.calendar
        let exported = Self.date(2026, 1, 15, calendar)

        func text(_ year: Int, _ month: Int, _ day: Int) -> String? {
            BackupModel.exportAgeText(
                exportedAt: exported,
                now: Self.date(year, month, day, calendar),
                calendar: calendar
            )
        }

        #expect(text(2026, 2, 15) == "1 か月前")
        #expect(text(2026, 12, 15) == "11 か月前")
        #expect(text(2027, 1, 14) == "11 か月前")
        #expect(text(2027, 1, 15) == "1 年前")
        #expect(text(2028, 7, 15) == "2 年前")
    }

    @Test
    func savesExportDateOnlyForJSON() async throws {
        let setup = try Setup()
        let model = BackupModel(database: setup.source, stash: setup.stash)
        let url = URL.temporaryDirectory.appending(path: "kakeibot.json")

        await model.makeFile(.json, at: setup.now)
        await model.finishExport(.success(url), at: setup.now)
        let saved = try await setup.source.setting(.backupExportedAt)

        #expect(saved != nil)
        #expect(model.file == nil)
    }

    @Test
    func takesExportDateFromRestoredFile() async throws {
        let setup = try Setup()
        let source = BackupModel(database: setup.source, stash: setup.stash)
        let target = BackupModel(database: setup.target, stash: setup.stash)
        let earlier = setup.now.addingTimeInterval(-90 * 24 * 60 * 60)
        try await setup.source.setSetting(.backupExportedAt, to: earlier)
        await source.makeFile(.json, at: setup.now)
        let file = try #require(source.file)

        target.read(file.data)
        await target.restore()
        let restored = try await setup.target.setting(.backupExportedAt)
        let text = String(decoding: file.data, as: UTF8.self)

        #expect(restored.map(\.timeIntervalSince1970) == setup.now.timeIntervalSince1970)
        #expect(!text.contains("backup_exported_at"))
    }

    @Test
    func skipsSavingExportDateForCSV() async throws {
        let setup = try Setup()
        let model = BackupModel(database: setup.source, stash: setup.stash)
        let url = URL.temporaryDirectory.appending(path: "kakeibot.csv")

        await model.makeFile(.csv, at: setup.now)
        await model.finishExport(.success(url), at: setup.now)
        let saved = try await setup.source.setting(.backupExportedAt)

        #expect(saved == nil)
    }

    @Test
    func skipsSavingExportDateOnFailure() async throws {
        let setup = try Setup()
        let model = BackupModel(database: setup.source, stash: setup.stash)

        await model.makeFile(.json, at: setup.now)
        await model.finishExport(.failure(CancellationError()), at: setup.now)
        let saved = try await setup.source.setting(.backupExportedAt)

        #expect(saved == nil)
        #expect(model.file == nil)
    }
}

private extension BackupModelTests {
    static var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)

        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .gmt

        return calendar
    }

    static func date(
        _ year: Int,
        _ month: Int,
        _ day: Int,
        _ calendar: Calendar
    ) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day)) ?? .distantPast
    }
}
