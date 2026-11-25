import Core
import DesignSystem
import FeatureModels
import SwiftUI

public struct AssetsView: View {
    @Bindable var model: AssetsModel

    @Environment(\.themeStyle.corner) var corner

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

                    if !model.output.upcomingBills.isEmpty {
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
        .errorBanner(Bindable(model.state).errorNotice)
        .sheet(item: Bindable(model.state).sheet, onDismiss: openPending) { sheet in
            sheetContent(sheet)
        }
        .backdrop()
    }
}

extension AssetsView {
    var ownedSections: [AssetsModel.WalletSection] {
        model.output.sections.filter { !Self.isOwed($0.role) }
    }

    var owedSections: [AssetsModel.WalletSection] {
        model.output.sections.filter { Self.isOwed($0.role) }
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
            CardHeader(model.output.showsNetWorth ? "純資産と推移" : "推移")

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
                    model.output.total,
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

            if model.output.outlook.isShown {
                outlookButton
            }
        }
    }
}

private extension AssetsView {
    var breakdownText: String {
        let holdings = model.output.holdings
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
        let change = model.output.changeFromLastMonth
        let sign = change > 0 ? "+" : ""
        return "先月末より \(sign)\(Yen.text(change))"
    }

    @ViewBuilder
    func sheetContent(_ sheet: AssetsModel.Sheet) -> some View {
        switch sheet {
        case .reward:
            AssetsRewardSheet(model: model)

        case .newGoal:
            AssetsRewardGoalEditSheet(model: model.goalEditModel(editing: nil))

        case let .newWallet(kind):
            WalletEditSheet(model: model.newWalletModel(kind: kind))

        case let .adjustment(row):
            AssetsAdjustmentSheet(model: model.adjustModel(for: row))

        case .outlook:
            AssetsOutlookSheet(
                model: model,
                onOpen: { id in
                    model.state.open(afterSheet: .entry(id))
                },
                onOpenRecurring: { id in
                    model.state.open(afterSheet: .recurring(id))
                }
            )

        case let .entries(source):
            AssetsEntrySheet(content: AssetsEntrySheet.Content(source)) { id in
                model.state.open(afterSheet: .entry(id))
            }
        }
    }

    static func isOwed(_ role: Wallet.Kind.Role) -> Bool {
        switch role {
        case .card, .loan: true
        case .onHand, .investment: false
        }
    }

    func addWallet(_ kind: Wallet.Kind) {
        model.state.present(.newWallet(kind))
    }

    func openPending() {
        switch model.state.takePending() {
        case let .entry(id): onOpenEntry(id)
        case let .recurring(id): onOpenRecurring(id)
        case nil: break
        }
    }
}
