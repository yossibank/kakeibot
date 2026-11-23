import Core
import DesignSystem
import SwiftUI

public struct AssetsView: View {
    @Bindable var model: AssetsModel

    @State var entrySheet: AssetsEntrySheet.Content?
    @State var isShowingReward = false
    @State var isAddingGoal = false
    @State var isAddingWallet = false
    @State var isShowingOutlook = false
    @State var addingKind = Wallet.Kind.cash
    @State var adjusting: AssetsModel.WalletRow?

    @Environment(\.themeStyle.corner) var corner

    @State private var pendingEntry: Entry.ID?
    @State private var pendingRecurring: Recurring.ID?

    let onOpenWallet: (Wallet.ID) -> Void
    let onOpenRecurring: (Recurring.ID) -> Void
    let onMarkReward: () -> Void

    private let onTransfer: () -> Void
    private let onOpenEntry: (Entry.ID) -> Void

    public init(
        model: AssetsModel,
        onTransfer: @escaping () -> Void,
        onOpenWallet: @escaping (Wallet.ID) -> Void,
        onOpenRecurring: @escaping (Recurring.ID) -> Void,
        onOpenEntry: @escaping (Entry.ID) -> Void,
        onMarkReward: @escaping () -> Void
    ) {
        self.model = model
        self.onTransfer = onTransfer
        self.onOpenWallet = onOpenWallet
        self.onOpenRecurring = onOpenRecurring
        self.onOpenEntry = onOpenEntry
        self.onMarkReward = onMarkReward
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                header

                TwoColumnStack(spacing: 12) {
                    totalCard

                    trendCard

                    if !model.upcomingBills.isEmpty {
                        billCard
                    }

                    ownedCard
                        .layoutColumn(.trailing)

                    owedCard
                        .layoutColumn(.trailing)

                    rewardCard
                        .padding(.top, 12)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .errorBanner($model.errorNotice)
        .sheet(isPresented: $isShowingReward) {
            AssetsRewardSheet(model: model)
        }
        .sheet(isPresented: $isAddingGoal) {
            AssetsRewardGoalEditSheet(model: model.goalEditModel(editing: nil))
        }
        .sheet(isPresented: $isAddingWallet) {
            WalletEditSheet(
                model: WalletEditModel(
                    database: model.database,
                    kind: addingKind
                )
            )
        }
        .sheet(item: $adjusting) { row in
            AssetsAdjustmentSheet(model: model.adjustModel(for: row))
        }
        .sheet(isPresented: $isShowingOutlook, onDismiss: openPendingEntry) {
            AssetsOutlookSheet(
                model: model,
                onOpen: { id in
                    pendingEntry = id
                },
                onOpenRecurring: { id in
                    pendingRecurring = id
                }
            )
        }
        .sheet(item: $entrySheet, onDismiss: openPendingEntry) { content in
            AssetsEntrySheet(content: content) { id in
                pendingEntry = id
            }
        }
        .backdrop()
    }
}

extension AssetsView {
    var ownedSections: [AssetsModel.WalletSection] {
        model.sections.filter { !Self.isOwed($0.role) }
    }

    var owedSections: [AssetsModel.WalletSection] {
        model.sections.filter { Self.isOwed($0.role) }
    }
}

private extension AssetsView {
    var header: some View {
        TabHeader("資産") {
            HeaderButton(
                systemImage: "arrow.left.arrow.right",
                title: "振替",
                action: onTransfer
            )
        }
    }

    var totalCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            CardHeader("手元のお金")

            totalContent
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
        .card()
    }

    var trendCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            CardHeader(model.showsNetWorth ? "純資産と推移" : "推移")

            trendContent
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
        .card()
    }

    var ownedCard: some View {
        walletGroup(
            "資産",
            sections: ownedSections,
            addNote: "現金・銀行・投資など"
        ) {
            addWallet(.cash)
        }
    }

    var owedCard: some View {
        walletGroup(
            "負債",
            sections: owedSections,
            addNote: "カード・借入"
        ) {
            addWallet(.card)
        }
    }

    var totalContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                AmountText(
                    model.total,
                    font: .size(.largeTitle, weight: .bold),
                    color: Palette.accentStrong
                )
                .lineLimit(1)
                .minimumScaleFactor(0.5)

                Text(changeText)
                    .textFont(.caption)
                    .monospacedDigit()
                    .foregroundStyle(Palette.accent)
            }

            Text(breakdownText)
                .textFont(.caption)
                .monospacedDigit()
                .foregroundStyle(Palette.subtext)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            if model.outlook.isShown {
                outlookButton
            }
        }
    }
}

private extension AssetsView {
    var breakdownText: String {
        let holdings = model.holdings
        let onHand = "手持ち \(Yen.text(holdings.onHand))"

        if holdings.unpaid > 0 {
            return "\(onHand)・未払い \(Yen.text(holdings.unpaid))"
        }

        if holdings.refund > 0 {
            return "\(onHand)・返ってくる額 \(Yen.text(holdings.refund))"
        }

        return onHand
    }

    var changeText: String {
        let change = model.changeFromLastMonth
        let sign = change > 0 ? "+" : ""
        return "先月末より \(sign)\(Yen.text(change))"
    }

    static func isOwed(_ role: Wallet.Kind.Role) -> Bool {
        switch role {
        case .card, .loan: true
        case .onHand, .investment: false
        }
    }

    func addWallet(_ kind: Wallet.Kind) {
        addingKind = kind
        isAddingWallet = true
    }

    func openPendingEntry() {
        if let pendingRecurring {
            self.pendingRecurring = nil

            onOpenRecurring(pendingRecurring)
        }

        guard let pendingEntry else {
            return
        }

        self.pendingEntry = nil

        onOpenEntry(pendingEntry)
    }
}
