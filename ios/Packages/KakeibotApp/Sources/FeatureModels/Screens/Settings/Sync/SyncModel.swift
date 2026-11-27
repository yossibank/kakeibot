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
        parts: ScreenParts,
        cloud: SyncCloud
    ) {
        let state = State(wait: parts.wait)
        let input = Input()

        self.state = state
        self.input = input
        self.output = Output(input: input, state: state)
        self.dependencies = Dependencies(database: parts.database, clock: parts.clock, cloud: cloud)
    }
}

public extension SyncModel {
    @MainActor
    @Observable
    final class State: NoticeHolding {
        public var presented = Presented()

        public internal(set) var workingWallet: Wallet.ID?

        public let errorNotice: ErrorNotice
        public let task = ModelTask()
        public let shareTask = ModelTask()

        var request = SwitchRequest()

        init(wait: ScreenWait) {
            self.errorNotice = ErrorNotice(wait: wait)
        }
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

        public let hint = SettingsFoldInput.hint(.sync)

        var members: Loadable<[SyncParticipant]> = .loading
        var pending: Loadable<Int> = .loading
    }
}

extension SyncModel {
    struct Dependencies {
        let database: AppDatabase
        let clock: ScreenClock
        let cloud: SyncCloud
    }
}

public extension SyncModel {
    static let loadFailedMessage = "同期の状態を読めませんでした"

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
            !state.task.isRunning,
            !output.isSwitching
        else {
            return false
        }

        state.request.ask(isOn)

        return true
    }

    func setOn(_ isOn: Bool) async {
        state.request.ask(isOn)

        if isOn {
            await turnOn()
        } else {
            await work {
                try await dependencies.database.turnOffSync()
            }
        }

        if !output.isChoosing {
            state.request.clear()
        }
    }

    func useCloudData() async {
        guard output.isChoosing else {
            return
        }

        state.closeChoice()

        await work {
            try await dependencies.database.turnOnSyncReplacingLocal()
        }

        state.request.clear()
    }

    func useLocalData() async {
        guard output.isChoosing else {
            return
        }

        state.closeChoice()

        await work {
            try await dependencies.cloud.deleteData()
            try await dependencies.database.turnOnSync()
        }

        state.request.clear()
    }

    func cancelChoice() {
        state.closeChoice()
        state.request.clear()
    }
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
        await state.task.attempt {
            input.account = await dependencies.cloud.account()

            guard output.isAvailable else {
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

                let choice = SyncChoice(local: localSummary, cloud: cloudSummary)

                state.presented.dialog.show(.choice(choice))
            }
        }
    }

    func work(_ operation: () async throws -> Void) async {
        state.errorNotice.clear()

        do {
            try await state.task.attempt {
                try await operation()
                input.isOn = try await dependencies.database.isSyncEnabled()
            }
        } catch {
            state.errorNotice.show(Self.saveFailedMessage, for: error)
        }
    }
}

extension SyncModel: ScreenModel {}

extension SyncModel: SettingsFoldModel {
    public func foldStore() -> SettingsFoldStore {
        SettingsFoldStore(dependencies.database)
    }
}
