import Core
import DesignSystem
import Foundation
import Observation
import Store

@MainActor
@Observable
public final class SyncModel {
    public private(set) var isOn = false
    public private(set) var account = SyncAccount.available
    public private(set) var isWorking = false
    public private(set) var pendingCount: Int?
    public private(set) var isPendingFailed = false
    public private(set) var stopReason: SyncStopReason?
    public private(set) var sendProblem: SyncSendProblem?
    public private(set) var isFetching = false
    public private(set) var syncedAt: Date?
    public private(set) var choice: SyncChoice?

    public internal(set) var shares: [WalletShare] = []
    public internal(set) var joined: [JoinedShare] = []
    public internal(set) var workingWallet: Wallet.ID?
    public internal(set) var invitation: WalletShare?
    public internal(set) var opened: WalletShare?
    public internal(set) var participants: [SyncParticipant]?
    public internal(set) var isParticipantsFailed = false
    public internal(set) var errorNotice = ErrorNotice()

    let database: AppDatabase
    let cloud: SyncCloud

    private var requestedOn: Bool?

    public init(
        database: AppDatabase,
        cloud: SyncCloud
    ) {
        self.database = database
        self.cloud = cloud
    }
}

public extension SyncModel {
    var isAvailable: Bool {
        account == .available
    }

    var isChoosing: Bool {
        choice != nil
    }

    var shownOn: Bool {
        requestedOn ?? isOn
    }

    var isSwitching: Bool {
        requestedOn != nil
    }

    var progress: SyncProgress? {
        if isWorking {
            return .switching
        }

        guard isOn else {
            return stopReason.map(SyncProgress.stopped)
        }

        guard let pendingCount else {
            return isPendingFailed ? nil : .checking
        }

        if isFetching {
            return .receiving
        }

        guard pendingCount > 0 else {
            return .upToDate(syncedAt)
        }

        return sendProblem.map { .stuck($0, pendingCount) } ?? .sending(pendingCount)
    }

    var footnote: String {
        guard !isOn else {
            return "切っても、この iPhone のデータは残ります。"
        }

        return switch account {
        case .available: "オンにすると、ほかの端末と記録がそろいます。"
        case .noAccount: "設定アプリで iCloud にサインインすると使えます。"
        case .restricted: "この iPhone では、制限で iCloud を使えません。"
        case .temporarilyUnavailable: "設定アプリで iCloud にサインインし直すと使えます。"
        case .couldNotDetermine: "iCloud の状態を確かめられませんでした。\n時間をおいて開き直してください。"
        }
    }

    func load() async {
        do {
            isOn = try await database.isSyncEnabled()
        } catch {
            errorNotice.show(Self.loadFailedMessage)
        }

        account = await cloud.account()
    }

    func refreshAccount() async {
        account = await cloud.account()
    }

    func observe() async {
        await withDiscardingTaskGroup { group in
            group.addTask {
                await self.observeStatus()
            }

            group.addTask {
                await self.observePending()
            }

            group.addTask {
                await self.observeShares()
            }

            group.addTask {
                await self.observeJoined()
            }
        }
    }

    func request(_ isOn: Bool) -> Bool {
        guard
            !isWorking,
            !isSwitching
        else {
            return false
        }

        requestedOn = isOn
        return true
    }

    func setOn(_ isOn: Bool) async {
        requestedOn = isOn

        if isOn {
            await turnOn()
        } else {
            await work {
                try await database.turnOffSync()
            }
        }

        if choice == nil {
            requestedOn = nil
        }
    }

    func useCloudData() async {
        guard isChoosing else {
            return
        }

        choice = nil

        await work {
            try await database.turnOnSyncReplacingLocal()
        }

        requestedOn = nil
    }

    func useLocalData() async {
        guard isChoosing else {
            return
        }

        choice = nil

        await work {
            try await cloud.deleteData()
            try await database.turnOnSync()
        }

        requestedOn = nil
    }

    func cancelChoice() {
        choice = nil
        requestedOn = nil
    }
}

extension SyncModel: ScreenModel {}

private extension SyncModel {
    static let loadFailedMessage = "同期の状態を読めませんでした"
    static let saveFailedMessage = "同期を切り替えられませんでした。時間をおいて試してください"

    func observeStatus() async {
        await observe(
            database.syncStatusUpdates(),
            failure: Self.loadFailedMessage
        ) { status in
            self.isOn = status.isEnabled
            self.stopReason = status.stopReason
            self.sendProblem = status.sendProblem
            self.isFetching = status.isFetching
            self.syncedAt = status.syncedAt
        }
    }

    func observePending() async {
        isPendingFailed = await observe(
            database.pendingSyncCountUpdates(),
            failure: Self.loadFailedMessage
        ) { count in
            self.pendingCount = count
        }
    }

    func observeShares() async {
        await observe(
            database.walletShareUpdates(),
            failure: Self.loadFailedMessage
        ) { shares in
            self.shares = shares
        }
    }

    func observeJoined() async {
        await observe(
            database.joinedShareUpdates(),
            failure: Self.loadFailedMessage
        ) { joined in
            self.joined = joined
        }
    }

    func turnOn() async {
        isWorking = true
        account = await cloud.account()

        guard isAvailable else {
            isWorking = false
            return
        }

        await work {
            guard let cloudSummary = try await cloud.summary() else {
                try await database.turnOnSync()
                return
            }

            let localSummary = try await database.syncSummary()

            guard localSummary.entryCount > 0 else {
                try await database.turnOnSyncReplacingLocal()
                return
            }

            choice = SyncChoice(local: localSummary, cloud: cloudSummary)
        }
    }

    func work(_ operation: () async throws -> Void) async {
        isWorking = true
        errorNotice.clear()

        do {
            try await operation()

            isOn = try await database.isSyncEnabled()
        } catch {
            errorNotice.show(Self.saveFailedMessage, for: error)
        }

        isWorking = false
    }
}
