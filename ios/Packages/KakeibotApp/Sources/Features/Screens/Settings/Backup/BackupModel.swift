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

    struct Previous: Equatable, Identifiable, Sendable {
        public let url: URL
        public let date: Date

        public var id: URL {
            url
        }
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

    func loadPrevious() async {
        let stash = stash

        previous = await Task.detached {
            Self.previous(in: stash)
        }.value
    }

    func previousDay(of item: Previous) -> String {
        Self.dayText(item.date)
    }

    func previousTitle(of item: Previous) -> String {
        let text = Self.dayTimeText(item.date)

        return "読み込む前のデータに戻す（\(text)）"
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

    func finishExport(_ result: Result<URL, any Error>) {
        file = nil

        switch result {
        case .success:
            doneMessage = Self.exportedMessage
        case .failure:
            errorNotice.show(Self.exportFailedMessage)
        }
    }

    func read(_ result: Result<URL, any Error>) -> Bool {
        doneMessage = nil

        guard case let .success(url) = result else {
            errorNotice.show(Self.readFailedMessage)
            return false
        }

        let isAccessing = url.startAccessingSecurityScopedResource()

        defer {
            if isAccessing {
                url.stopAccessingSecurityScopedResource()
            }
        }

        guard let data = try? Data(contentsOf: url) else {
            errorNotice.show(Self.readFailedMessage)
            return false
        }

        return read(data)
    }

    @discardableResult
    func read(_ data: Data) -> Bool {
        do {
            pending = try ExportV1(json: data)
            return true
        } catch {
            errorNotice.show(Self.readMessage(for: error))
            return false
        }
    }

    @discardableResult
    func readPrevious(_ item: Previous) async -> Bool {
        doneMessage = nil

        let result = await Task.detached {
            Result { try ExportV1(json: Data(contentsOf: item.url)) }
        }.value

        do {
            pending = try result.get()
            return true
        } catch {
            errorNotice.show(Self.readMessage(for: error))
            return false
        }
    }

    func cancelRestore() {
        pending = nil
    }

    func restore() async {
        guard let pending else {
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

            doneMessage = Self.restoredMessage

            if pending.data.needsNotifications {
                await permission.requestIfUndecided()
            }
        } catch {
            errorNotice.show(Self.restoreFailedMessage)
        }

        await loadPrevious()
        self.pending = nil
    }
}

private extension ExportV1.Tables {
    var needsNotifications: Bool {
        let hasReminder = settings.contains { $0.key == .reminderTime }
        let hasNotice = recurrings.contains { $0.archivedAt == nil && $0.remindDaysBefore != nil }

        return hasReminder || hasNotice
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
    static let restoreFailedMessage = "読み込めませんでした。いまのデータはそのままです"

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

    nonisolated static func previous(in stash: BackupStash) -> [Previous] {
        stash.load().compactMap { item in
            (try? ExportV1(json: item.data)).map {
                Previous(url: item.url, date: $0.exportedAt)
            }
        }
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
