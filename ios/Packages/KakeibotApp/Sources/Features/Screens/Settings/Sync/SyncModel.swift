import Core
import DesignSystem
import Foundation
import Observation
import Store

@MainActor
@Observable
public final class SyncModel {
    public let state: State
    public let input: Input
    public let output: Output

    let dependencies: Dependencies

    public init(
        database: AppDatabase,
        clock: ScreenClock,
        cloud: SyncCloud
    ) {
        let state = State()
        let input = Input()

        self.state = state
        self.input = input
        self.output = Output(input: input, state: state)
        self.dependencies = Dependencies(database: database, clock: clock, cloud: cloud)
    }
}

public extension SyncModel {
    @MainActor
    @Observable
    final class State: NoticeHolding {
        public internal(set) var errorNotice = ErrorNotice()

        public internal(set) var isWorking = false
        public internal(set) var choice: SyncChoice?
        public internal(set) var workingWallet: Wallet.ID?
        public internal(set) var invitation: WalletShare?
        public internal(set) var opened: WalletShare?

        var requestedOn: Bool?
    }

    @MainActor
    @Observable
    final class Input {
        public internal(set) var isOn = false
        public internal(set) var account = SyncAccount.available
        public internal(set) var stopReason: SyncStopReason?
        public internal(set) var sendProblem: SyncSendProblem?
        public internal(set) var isFetching = false
        public internal(set) var syncedAt: Date?
        public internal(set) var shares: [WalletShare] = []
        public internal(set) var joined: [JoinedShare] = []

        var members: Loadable<[SyncParticipant]> = .loading
        var pending: Loadable<Int> = .loading
    }

    internal(set) var errorNotice: ErrorNotice {
        get {
            state.errorNotice
        }
        set {
            state.errorNotice = newValue
        }
    }

    func hintFlag() -> SettingsScreenFlag {
        .closedHint(.sync, in: dependencies.database)
    }

    func load() async {
        do {
            input.isOn = try await dependencies.database.isSyncEnabled()
        } catch {
            state.errorNotice.show(Self.loadFailedMessage)
        }

        input.account = await dependencies.cloud.account()
    }

    func refreshAccount() async {
        input.account = await dependencies.cloud.account()
    }

    func observe() async {
        await observeAll([
            {
                await self.observeStatus()
            },
            {
                await self.observePending()
            },
            {
                await self.observe(
                    self.dependencies.database.walletShareUpdates(),
                    into: \.input.shares
                )
            },
            {
                await self.observe(
                    self.dependencies.database.joinedShareUpdates(),
                    into: \.input.joined
                )
            }
        ])
    }

    func request(_ isOn: Bool) -> Bool {
        guard
            !state.isWorking,
            !output.isSwitching
        else {
            return false
        }

        state.requestedOn = isOn
        return true
    }

    func setOn(_ isOn: Bool) async {
        state.requestedOn = isOn

        if isOn {
            await turnOn()
        } else {
            await work {
                try await dependencies.database.turnOffSync()
            }
        }

        if state.choice == nil {
            state.requestedOn = nil
        }
    }

    func useCloudData() async {
        guard output.isChoosing else {
            return
        }

        state.choice = nil

        await work {
            try await dependencies.database.turnOnSyncReplacingLocal()
        }

        state.requestedOn = nil
    }

    func useLocalData() async {
        guard output.isChoosing else {
            return
        }

        state.choice = nil

        await work {
            try await dependencies.cloud.deleteData()
            try await dependencies.database.turnOnSync()
        }

        state.requestedOn = nil
    }

    func cancelChoice() {
        state.choice = nil
        state.requestedOn = nil
    }
}

extension SyncModel: ScreenModel {}

extension SyncModel {
    struct Dependencies {
        let database: AppDatabase
        let clock: ScreenClock
        let cloud: SyncCloud
    }

    static let loadFailedMessage = "同期の状態を読めませんでした"
}

private extension SyncModel {
    static let saveFailedMessage = "同期を切り替えられませんでした。時間をおいて試してください"

    func observeStatus() async {
        await observe(
            dependencies.database.syncStatusUpdates(),
            failure: Self.loadFailedMessage
        ) { status in
            self.input.isOn = status.isEnabled
            self.input.stopReason = status.stopReason
            self.input.sendProblem = status.sendProblem
            self.input.isFetching = status.isFetching
            self.input.syncedAt = status.syncedAt
        }
    }

    func observePending() async {
        let isFailed = await observe(
            dependencies.database.pendingSyncCountUpdates(),
            failure: Self.loadFailedMessage
        ) { count in
            self.input.pending = .loaded(count)
        }

        if isFailed,
           !input.pending.isLoaded {
            input.pending = .failed
        }
    }

    func turnOn() async {
        state.isWorking = true
        input.account = await dependencies.cloud.account()

        guard output.isAvailable else {
            state.isWorking = false
            return
        }

        await work {
            guard let cloudSummary = try await dependencies.cloud.summary() else {
                try await dependencies.database.turnOnSync()
                return
            }

            let localSummary = try await dependencies.database.syncSummary()

            guard localSummary.entryCount > 0 else {
                try await dependencies.database.turnOnSyncReplacingLocal()
                return
            }

            state.choice = SyncChoice(local: localSummary, cloud: cloudSummary)
        }
    }

    func work(_ operation: () async throws -> Void) async {
        state.isWorking = true
        state.errorNotice.clear()

        do {
            try await operation()

            input.isOn = try await dependencies.database.isSyncEnabled()
        } catch {
            state.errorNotice.show(Self.saveFailedMessage, for: error)
        }

        state.isWorking = false
    }
}
