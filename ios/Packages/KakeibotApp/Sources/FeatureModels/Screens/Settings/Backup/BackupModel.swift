import Core
import DesignSystem
import Foundation
import Observation
import Store

@MainActor
@Observable
public final class BackupModel {
    public let state = State()
    public let input: Input
    public let output: Output

    let dependencies: Dependencies

    public init(
        parts: ScreenParts,
        stash: BackupStash = .standard,
        appVersion: String = Bundle.main.shortVersion,
        permission: NotificationPermission = .allowed
    ) {
        let input = Input()

        self.input = input
        self.output = Output(state: state)

        self.dependencies = Dependencies(
            database: parts.database,
            clock: parts.clock,
            stash: stash,
            appVersion: appVersion,
            permission: permission
        )
    }
}

public extension BackupModel {
    @MainActor
    @Observable
    final class State: NoticeHolding {
        public var errorNotice = ErrorNotice()

        public internal(set) var file: BackupFile?
        public internal(set) var pending: ExportV1?
        public internal(set) var doneMessage: String?
        public internal(set) var isWorking = false
    }

    @MainActor
    @Observable
    final class Input {
        public internal(set) var isSyncActive = false
        public internal(set) var previous: [Previous] = []
    }

    @MainActor
    final class Output {
        let state: State

        public var pendingSummary: String? {
            guard let pending = state.pending else {
                return nil
            }

            let data = pending.data
            let date = BackupModel.dayText(pending.exportedAt)
            let counts = "記録 \(data.entries.count) 件・口座 \(data.wallets.count) 件"

            return "\(date) に書き出した\(counts)に置き換えます。いまのデータは退避するので、読み込んだ後もこの画面から戻せます"
        }

        init(state: State) {
            self.state = state
        }

        public func previousTitle(of item: Previous) -> String {
            let text = BackupModel.dayTimeText(item.date)
            return "\(text) の退避に戻す"
        }
    }
}

extension BackupModel {
    struct Dependencies {
        let database: AppDatabase
        let clock: ScreenClock
        let stash: BackupStash
        let appVersion: String
        let permission: NotificationPermission
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

    func hintFlag() -> SettingsScreenFlag {
        .closedHint(.backup, in: dependencies.database)
    }

    func observeSync() async {
        do {
            for try await activity in dependencies.database.syncActivityUpdates() {
                input.isSyncActive = activity.isActive
            }
        } catch {
            input.isSyncActive = false
        }
    }

    func loadPrevious() async {
        let stash = dependencies.stash

        input.previous = await Task.detached {
            Self.previous(in: stash)
        }.value
    }

    @discardableResult
    func makeFile(_ kind: FileKind) async -> Bool {
        let date = dependencies.clock.now

        state.isWorking = true
        state.doneMessage = nil

        defer {
            state.isWorking = false
        }

        do {
            let data = try await data(of: kind, at: date)
            let name = Self.fileName(of: kind, at: date)

            state.file = BackupFile(kind: kind, data: data, name: name)

            return true
        } catch {
            state.errorNotice.show(Self.exportFailedMessage)
            return false
        }
    }

    func finishExport(_ result: Result<URL, any Error>) async {
        let kind = state.file?.kind

        state.file = nil

        switch result {
        case .success:
            state.doneMessage = Self.exportedMessage

            if kind == .json {
                try? await dependencies.database.setSetting(
                    .backupExportedAt,
                    to: dependencies.clock.now
                )
            }

        case .failure:
            state.errorNotice.show(Self.exportFailedMessage)
        }
    }

    func read(_ result: Result<URL, any Error>) async -> Bool {
        state.doneMessage = nil

        guard case let .success(url) = result else {
            state.errorNotice.show(Self.readFailedMessage)
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
        state.doneMessage = nil

        let export = await Task.detached {
            Result {
                try ExportV1(json: Data(contentsOf: item.url))
            }
        }.value

        return accept(export)
    }

    func cancelRestore() {
        state.pending = nil
    }

    func restore() async {
        guard let pending = state.pending else {
            return
        }

        guard await !isSyncActiveNow() else {
            state.pending = nil
            state.errorNotice.show(Self.syncActiveMessage)
            return
        }

        state.isWorking = true

        defer {
            state.isWorking = false
        }

        do {
            let app = ExportV1.App(platform: .ios, version: dependencies.appVersion)
            let stash = dependencies.stash

            try await dependencies.database.restoreBackup(
                pending,
                stashingAt: dependencies.clock.now,
                app: app
            ) {
                try stash.save($0)
            }

            try? await dependencies.database.setSetting(.backupExportedAt, to: pending.exportedAt)

            state.doneMessage = Self.restoredMessage

            if pending.data.needsNotifications {
                await dependencies.permission.requestIfUndecided()
            }
        } catch {
            state.errorNotice.show(Self.restoreFailedMessage, for: error)
        }

        await loadPrevious()
        state.pending = nil
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

    func accept(_ export: Result<ExportV1, any Error>) -> Bool {
        do {
            state.pending = try export.get()
            return true
        } catch {
            state.errorNotice.show(Self.readMessage(for: error))
            return false
        }
    }

    func isSyncActiveNow() async -> Bool {
        do {
            for try await activity in dependencies.database.syncActivityUpdates() {
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
            let app = ExportV1.App(platform: .ios, version: dependencies.appVersion)
            return try await dependencies.database.backup(at: date, app: app)

        case .csv:
            return try await dependencies.database.spreadsheet()
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
