import Core
import DesignSystem
import Foundation
import Observation
import Store

@MainActor
@Observable
public final class BackupModel {
    public private(set) var file: BackupFile?
    public private(set) var pending: ExportV1?
    public private(set) var doneMessage: String?
    public private(set) var isWorking = false
    public private(set) var isSyncActive = false
    public private(set) var previous: [Previous] = []

    public internal(set) var errorNotice = ErrorNotice()

    private let database: AppDatabase
    private let stash: BackupStash
    private let appVersion: String
    private let permission: NotificationPermission

    public init(
        database: AppDatabase,
        stash: BackupStash = .standard,
        appVersion: String = Bundle.main.shortVersion,
        permission: NotificationPermission = .allowed
    ) {
        self.database = database
        self.stash = stash
        self.permission = permission
        self.appVersion = appVersion
    }
}

public extension BackupModel {
    struct BackupFile: Equatable, Sendable {
        public let kind: FileKind
        public let data: Data
        public let name: String
    }

    struct Previous: Equatable, Sendable {
        public let url: URL
        public let date: Date
    }

    enum FileKind: String, Sendable {
        case json
        case csv
    }

    var pendingSummary: String? {
        guard let pending else {
            return nil
        }

        let data = pending.data
        let date = Self.dayText(pending.exportedAt)
        let counts = "記録 \(data.entries.count) 件・口座 \(data.wallets.count) 件"

        return "\(date) に書き出した\(counts)に置き換えます。いまのデータは退避するので、読み込んだ後もこの画面から戻せます"
    }

    static func exportAgeText(
        exportedAt: Date?,
        firstCreatedAt: Date? = nil,
        now: Date,
        calendar: Calendar = .current
    ) -> String? {
        guard let since = exportedAt ?? firstCreatedAt else {
            return nil
        }

        let months = calendar.dateComponents([.month], from: since, to: now).month ?? 0

        guard months >= 1 else {
            return nil
        }

        guard exportedAt != nil else {
            return "未"
        }

        return months < 12 ? "\(months) か月前" : "\(months / 12) 年前"
    }

    func loadSync() async {
        do {
            for try await activity in database.syncActivityUpdates() {
                isSyncActive = activity.isActive
            }
        } catch {
            isSyncActive = false
        }
    }

    func loadPrevious() async {
        let stash = stash

        previous = await Task.detached {
            Self.previous(in: stash)
        }.value
    }

    func previousTitle(of item: Previous) -> String {
        let text = Self.dayTimeText(item.date)
        return "\(text) の退避に戻す"
    }

    @discardableResult
    func makeFile(
        _ kind: FileKind,
        at date: Date
    ) async -> Bool {
        isWorking = true
        doneMessage = nil

        defer {
            isWorking = false
        }

        do {
            let data = try await data(of: kind, at: date)
            let name = Self.fileName(of: kind, at: date)

            file = BackupFile(kind: kind, data: data, name: name)

            return true
        } catch {
            errorNotice.show(Self.exportFailedMessage)
            return false
        }
    }

    func finishExport(
        _ result: Result<URL, any Error>,
        at date: Date
    ) async {
        let kind = file?.kind

        file = nil

        switch result {
        case .success:
            doneMessage = Self.exportedMessage

            if kind == .json {
                try? await database.setSetting(.backupExportedAt, to: date)
            }

        case .failure:
            errorNotice.show(Self.exportFailedMessage)
        }
    }

    func read(_ result: Result<URL, any Error>) async -> Bool {
        doneMessage = nil

        guard case let .success(url) = result else {
            errorNotice.show(Self.readFailedMessage)
            return false
        }

        let export = await Task.detached {
            Result {
                let isAccessing = url.startAccessingSecurityScopedResource()

                defer {
                    if isAccessing {
                        url.stopAccessingSecurityScopedResource()
                    }
                }

                return try ExportV1(json: Data(contentsOf: url))
            }
        }.value

        return accept(export)
    }

    @discardableResult
    func read(_ data: Data) -> Bool {
        accept(Result { try ExportV1(json: data) })
    }

    @discardableResult
    func readPrevious(_ item: Previous) async -> Bool {
        doneMessage = nil

        let export = await Task.detached {
            Result {
                try ExportV1(json: Data(contentsOf: item.url))
            }
        }.value

        return accept(export)
    }

    func cancelRestore() {
        pending = nil
    }

    func restore() async {
        guard let pending else {
            return
        }

        guard await !isSyncActiveNow() else {
            self.pending = nil
            errorNotice.show(Self.syncActiveMessage)
            return
        }

        isWorking = true

        defer {
            isWorking = false
        }

        do {
            let app = ExportV1.App(platform: .ios, version: appVersion)
            let stash = stash

            try await database.restoreBackup(
                pending,
                stashingAt: Date(),
                app: app
            ) {
                try stash.save($0)
            }

            try? await database.setSetting(.backupExportedAt, to: pending.exportedAt)

            doneMessage = Self.restoredMessage

            if pending.data.needsNotifications {
                await permission.requestIfUndecided()
            }
        } catch {
            errorNotice.show(Self.restoreFailedMessage, for: error)
        }

        await loadPrevious()
        self.pending = nil
    }
}

private extension BackupModel {
    static let exportedMessage = "書き出しました"
    static let restoredMessage = "読み込みました"
    static let exportFailedMessage = "書き出せませんでした"
    static let readFailedMessage = "ファイルを読めませんでした"
    static let unknownFormatMessage = "かけいぼっとのバックアップではありません"
    static let newerVersionMessage = "新しい版のアプリで書き出したファイルです"
    static let missingTransferMessage = "元の振替が無い手数料があるため、読み込めません"
    static let restoreFailedMessage = "バックアップを読めませんでした。いまのデータはそのままです"
    static let syncActiveMessage = "同期と共有をやめると、読み込めます"

    nonisolated static func previous(in stash: BackupStash) -> [Previous] {
        stash.load().compactMap { item in
            (try? ExportV1(json: item.data)).map {
                Previous(url: item.url, date: $0.exportedAt)
            }
        }
    }

    static func readMessage(for error: any Error) -> String {
        switch error as? ExportV1.ReadError {
        case .unknownFormat: unknownFormatMessage
        case .unsupportedVersion: newerVersionMessage
        case .missingTransfer: missingTransferMessage
        case nil: readFailedMessage
        }
    }

    static func fileName(
        of kind: FileKind,
        at date: Date
    ) -> String {
        let formatter = DateFormatter()

        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"

        return "kakeibot-\(formatter.string(from: date)).\(kind.rawValue)"
    }

    static func dayText(_ date: Date) -> String {
        let formatter = DateFormatter()

        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "yyyy/M/d"

        return formatter.string(from: date)
    }

    static func dayTimeText(_ date: Date) -> String {
        let formatter = DateFormatter()

        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "yyyy/M/d H:mm"

        return formatter.string(from: date)
    }

    func accept(_ export: Result<ExportV1, any Error>) -> Bool {
        do {
            pending = try export.get()
            return true
        } catch {
            errorNotice.show(Self.readMessage(for: error))
            return false
        }
    }

    func isSyncActiveNow() async -> Bool {
        do {
            for try await activity in database.syncActivityUpdates() {
                return activity.isActive
            }
        } catch {
            return true
        }

        return true
    }

    func data(
        of kind: FileKind,
        at date: Date
    ) async throws -> Data {
        switch kind {
        case .json:
            let app = ExportV1.App(platform: .ios, version: appVersion)
            return try await database.backup(at: date, app: app)

        case .csv:
            return try await database.spreadsheet()
        }
    }
}

extension BackupModel.Previous: Identifiable {
    public var id: URL {
        url
    }
}

private extension ExportV1.Tables {
    var needsNotifications: Bool {
        let hasReminder = settings.contains { $0.key == .reminderTime }
        let hasNotice = recurrings.contains { $0.archivedAt == nil && $0.remindDaysBefore != nil }
        return hasReminder || hasNotice
    }
}
