import Core
import DesignSystem
import Foundation
import Observation
import Store

@MainActor
@Observable
public final class AssetsModel: ScreenModel {
    public let state: State
    public let input: Input
    public let output: Output

    let dependencies: ScreenParts

    public init(
        parts: ScreenParts,
        today: LocalDate
    ) {
        let state = State()
        let input = Input(today: today)

        self.state = state
        self.input = input
        self.output = Output(input: input, state: state)
        self.dependencies = parts
    }
}

public extension AssetsModel {
    @MainActor
    @Observable
    final class State: NoticeHolding {
        public var errorNotice = ErrorNotice()

        public var billPage = 0
        public var boughtId: RewardGoal.ID?
        public var sheet: Sheet?

        public internal(set) var reward = RewardSheet()
        public internal(set) var pending: Opening?
    }

    @MainActor
    @Observable
    final class Input {
        public internal(set) var isListFailed = false
        public internal(set) var rewardBank: RewardBank?

        var summary: AssetsSummary

        @ObservationIgnored var latest: AssetsSummary.Input
        @ObservationIgnored var isRefreshing = false
        @ObservationIgnored var needsRefresh = false

        init(today: LocalDate) {
            let latest = AssetsSummary.Input(today: today)

            self.latest = latest
            self.summary = AssetsSummary(latest)
        }
    }

    static let monthCount = AssetsSummary.Input.monthCount

    func setToday(_ today: LocalDate) {
        guard today != input.latest.today else {
            return
        }

        input.latest.today = today
        refreshLater()
    }

    func newWalletModel(kind: Wallet.Kind) -> WalletEditModel {
        WalletEditModel(
            parts: dependencies,
            kind: kind
        )
    }

    func adjustModel(for row: WalletRow) -> AssetsAdjustmentModel {
        AssetsAdjustmentModel(
            parts: dependencies,
            wallet: row.wallet,
            balance: row.balance,
            today: output.today
        )
    }

    func run() async {
        await observeAll([
            {
                await self.observe()
            },
            {
                await self.observeMonthStartDay()
            },
            {
                await self.observeRecurrings()
            },
            {
                await self.observe(
                    self.dependencies.database.rewardBankUpdates(),
                    into: \.input.rewardBank
                )
            }
        ])
    }

    func load() async {
        do {
            input.latest.list = try await dependencies.database.entryList()
            input.latest.recurrings = try await dependencies.database.recurrings()
        } catch {
            state.errorNotice.show(Self.loadFailedMessage)
        }

        await refresh()
    }
}

public extension AssetsModel {
    static let loadFailedMessage = "残高を読めませんでした"
}

private extension AssetsModel {
    func refreshLater() {
        Task {
            await refresh()
        }
    }

    func refresh() async {
        input.needsRefresh = true

        guard !input.isRefreshing else {
            return
        }

        input.isRefreshing = true

        defer {
            input.isRefreshing = false
        }

        while input.needsRefresh {
            input.needsRefresh = false

            let summary = await AssetsSummary.make(input.latest)

            input.summary = summary
            state.billPage = BillPage.clamped(state.billPage, in: summary.billPages)
        }
    }

    func observe() async {
        input.isListFailed = false

        input.isListFailed = await observe(
            dependencies.database.entryListUpdates(),
            failure: Self.loadFailedMessage
        ) { list in
            input.latest.list = list
            refreshLater()
        }
    }

    func observeRecurrings() async {
        await observe(
            dependencies.database.recurringUpdates(),
            failure: Self.loadFailedMessage
        ) { recurrings in
            input.latest.recurrings = recurrings
            refreshLater()
        }
    }

    func observeMonthStartDay() async {
        await observe(
            dependencies.database.settingUpdates(.monthStartDay),
            failure: Self.loadFailedMessage
        ) { startDay in
            input.latest.monthStartDay = startDay
            refreshLater()
        }
    }
}
