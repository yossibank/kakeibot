import Core
import DesignSystem
import SwiftUI

public struct AssetsView: View {
    @Bindable var model: AssetsModel

    @State var entrySheet: AssetsEntrySheet.Content?
    @State var isShowingReward = false
    @State var isAddingGoal = false
    @State var isAddingWallet = false
    @State var adjusting: AssetsModel.WalletRow?

    @Environment(\.themeStyle.corner) var corner

    @State private var pendingEntry: Entry.ID?

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

                    if !model.upcomingBills.isEmpty {
                        billCard
                    }

                    ownedCard
                        .layoutColumn(.trailing)

                    if !owedSections.isEmpty {
                        walletGroup("負債", sections: owedSections)
                            .layoutColumn(.trailing)
                    }

                    rewardCard
                        .padding(.top, 12)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .errorBanner(model.errorNotice) {
            model.errorNotice.clear()
        }
        .sheet(isPresented: $isShowingReward) {
            AssetsRewardSheet(model: model)
        }
        .sheet(isPresented: $isAddingGoal) {
            AssetsGoalSheet(model: model.goalEditModel(editing: nil))
        }
        .sheet(isPresented: $isAddingWallet) {
            WalletEditSheet(model: WalletEditModel(database: model.database))
        }
        .sheet(item: $adjusting) { row in
            AssetsAdjustSheet(model: model.adjustModel(for: row))
        }
        .sheet(item: $entrySheet, onDismiss: openPendingEntry) { content in
            AssetsEntrySheet(content: content) { id in
                pendingEntry = id
            }
        }
        .background {
            Backdrop()
                .ignoresSafeArea()
        }
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

    var ownedCard: some View {
        walletGroup("資産", sections: ownedSections) {
            isAddingWallet = true
        }
    }

    var totalContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(AmountText.text(model.total))
                    .displayFont(.largeTitle, weight: .bold)
                    .monospacedDigit()
                    .foregroundStyle(Palette.accentStrong)
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

            if model.showsNetWorth {
                netWorthRow
            }

            AssetsBalanceTrend(
                totals: model.monthTotals.map(\.total),
                netWorths: netWorths
            )
            .frame(height: 70)

            if model.showsNetWorth {
                trendLegend
            }

            HStack(spacing: 0) {
                ForEach(model.monthTotals) { total in
                    Text("\(total.month.month)月")
                        .textFont(size: .micro)
                        .foregroundStyle(monthColor(total.month))
                        .frame(maxWidth: .infinity)
                }
            }
        }
    }

    var trendLegend: some View {
        HStack(spacing: 16) {
            legend("手元のお金", dash: [])
            legend("純資産", dash: AssetsBalanceTrend.netWorthDash)
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
    }

    var netWorthTitle: some View {
        Text("純資産")
            .textFont(.caption)
            .foregroundStyle(Palette.text)
            .fixedSize()
    }

    var netWorthNote: some View {
        Text("投資と借入を含む")
            .textFont(.caption2)
            .foregroundStyle(Palette.hint)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
    }

    var netWorthAmount: some View {
        Text(AmountText.text(model.holdings.netWorth))
            .displayFont(.headline)
            .monospacedDigit()
            .foregroundStyle(Palette.accentStrong)
            .lineLimit(1)
            .minimumScaleFactor(0.5)
    }

    var netWorthRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 2) {
                        netWorthTitle

                        netWorthNote
                    }

                    Spacer(minLength: 8)

                    netWorthAmount
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        netWorthTitle

                        netWorthNote
                    }

                    netWorthAmount
                }
            }

            if !owedSections.isEmpty {
                VStack(spacing: 4) {
                    SplitBar(
                        ownedShare,
                        leading: Palette.accent,
                        trailing: Palette.accent.opacity(.muted)
                    )

                    HStack {
                        Text("資産 \(AmountText.text(ownedTotal))")

                        Spacer(minLength: 8)

                        Text("負債 \(AmountText.text(-owedTotal))")
                    }
                    .textFont(size: .micro)
                    .monospacedDigit()
                    .foregroundStyle(Palette.subtext)
                }
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 12)
        .background(
            Palette.accent.opacity(.faint),
            in: .rect(cornerRadius: corner.radius(16))
        )
    }

    func legend(
        _ title: String,
        dash: [CGFloat]
    ) -> some View {
        HStack(spacing: 8) {
            Path { path in
                path.move(to: CGPoint(x: 0, y: 1))
                path.addLine(to: CGPoint(x: 16, y: 1))
            }
            .stroke(
                Palette.accent,
                style: StrokeStyle(lineWidth: 1.6, dash: dash)
            )
            .frame(width: 16, height: 2)

            Text(title)
                .textFont(size: .micro)
                .foregroundStyle(Palette.subtext)
        }
    }
}

private extension AssetsView {
    var ownedSections: [AssetsModel.WalletSection] {
        model.sections.filter { !Self.isOwed($0.role) }
    }

    var owedSections: [AssetsModel.WalletSection] {
        model.sections.filter { Self.isOwed($0.role) }
    }

    var ownedTotal: Int {
        ownedSections.flatMap(\.rows).reduce(0) { $0 + $1.balance }
    }

    var owedTotal: Int {
        owedSections.flatMap(\.rows).reduce(0) { $0 + $1.balance }
    }

    var ownedShare: Double {
        let owned = max(ownedTotal, 0)
        let owed = max(-owedTotal, 0)
        let total = owned + owed
        return total == 0 ? 1 : Double(owned) / Double(total)
    }

    var netWorths: [Int]? {
        model.showsNetWorth ? model.monthTotals.map(\.netWorth) : nil
    }

    var breakdownText: String {
        let holdings = model.holdings
        let onHand = "手持ち \(AmountText.text(holdings.onHand))"

        if holdings.unpaid > 0 {
            return "\(onHand)・未払い \(AmountText.text(holdings.unpaid))"
        }

        if holdings.refund > 0 {
            return "\(onHand)・返ってくる額 \(AmountText.text(holdings.refund))"
        }

        return onHand
    }

    var changeText: String {
        let change = model.changeFromLastMonth
        let sign = change > 0 ? "+" : ""
        return "先月末より \(sign)\(AmountText.text(change))"
    }

    static func isOwed(_ role: Wallet.Kind.Role) -> Bool {
        switch role {
        case .card, .loan: true
        case .onHand, .investment: false
        }
    }

    func monthColor(_ month: YearMonth) -> Color {
        month == model.currentMonth ? Palette.accent : Palette.hint
    }

    func openPendingEntry() {
        guard let pendingEntry else {
            return
        }

        self.pendingEntry = nil

        onOpenEntry(pendingEntry)
    }
}
