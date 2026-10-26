import Core
import DesignSystem
import SwiftUI

public struct AssetsView: View {
    @Bindable private var model: AssetsModel

    @State private var movedBill: AssetsModel.UpcomingBill?
    @State private var pendingEntry: Entry.ID?
    @State private var isShowingReward = false
    @State private var isAddingGoal = false

    @Environment(\.themeStyle.corner) private var corner

    private let onTransfer: () -> Void
    private let onOpenWallet: (Wallet.ID) -> Void
    private let onOpenRecurring: (Recurring.ID) -> Void
    private let onOpenEntry: (Entry.ID) -> Void
    private let onMarkReward: () -> Void

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

                totalCard

                if !model.upcomingBills.isEmpty {
                    billCard
                }

                if !ownedSections.isEmpty {
                    walletGroup(
                        "資産",
                        systemImage: "yensign",
                        sections: ownedSections
                    )
                }

                if !owedSections.isEmpty {
                    walletGroup(
                        "負債",
                        systemImage: "arrow.uturn.backward",
                        sections: owedSections
                    )
                }

                rewardCard
                    .padding(.top, 12)
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
        .sheet(item: $movedBill, onDismiss: openPendingEntry) { bill in
            AssetsMovedSheet(row: bill) { id in
                pendingEntry = id
            }
        }
        .background {
            Rectangle()
                .fill(Palette.background)
                .ignoresSafeArea()
        }
    }
}

private extension AssetsView {
    var header: some View {
        HStack {
            Text("資産")
                .displayFont(.body)
                .tracking(3)
                .foregroundStyle(Palette.accent)

            Spacer()

            HeaderButton(
                systemImage: "arrow.left.arrow.right",
                title: "振替",
                action: onTransfer
            )
        }
    }

    var totalCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle("手元のお金")

            HStack(alignment: .firstTextBaseline) {
                Text(AmountText.text(model.total))
                    .displayFont(.largeTitle, weight: .bold)
                    .monospacedDigit()
                    .foregroundStyle(Palette.accentStrong)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)

                Spacer(minLength: 8)

                Text(changeText)
                    .textFont(.caption)
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

            BalanceTrend(
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
        .padding(16)
        .card(cornerRadius: 24)
    }

    var rewardCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button {
                isShowingReward = true
            } label: {
                rewardCardBody
            }
            .buttonStyle(.plain)

            if model.rewardGoal == nil {
                AddButton("欲しい物を目標にする") {
                    isAddingGoal = true
                }
            }

            Button(action: onMarkReward) {
                Label("今日の達成を付ける", systemImage: "gift")
                    .textFont(.footnote)
                    .foregroundStyle(Palette.accent)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .overlay {
                        Capsule()
                            .stroke(Palette.accent.opacity(.medium), lineWidth: 1)
                    }
                    .contentShape(Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .card()
        .overlay {
            if model.isRewardGoalReached {
                reachedGlow
            }
        }
    }

    var rewardCardBody: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "gift.fill")
                    .sansFont(.small)
                    .foregroundStyle(Palette.accent)
                    .frame(width: 26, height: 26)
                    .background(Palette.accent.opacity(.subtle), in: Circle())

                SectionTitle("ごほうび貯金箱")

                Spacer()

                if model.isRewardGoalReached {
                    Text("目標に届きました")
                        .textFont(.caption2, weight: .semibold)
                        .foregroundStyle(Palette.background)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(Palette.accent, in: .capsule)
                }

                Image(systemName: "chevron.right")
                    .font(.footnote)
                    .foregroundStyle(Palette.hint)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(AmountText.text(model.rewardBalance))
                    .displayFont(.title)
                    .monospacedDigit()
                    .foregroundStyle(Palette.accentStrong)

                Text("我慢できた日に決めた額を貯めていきます")
                    .textFont(.caption)
                    .foregroundStyle(Palette.subtext)

                Text("口座の残高は変わりません")
                    .textFont(.caption2)
                    .foregroundStyle(Palette.hint)
            }

            if let goal = model.rewardGoal {
                goalLine(goal)
            }

            if !model.recentRewards.isEmpty {
                VStack(spacing: 8) {
                    ForEach(model.recentRewards) { log in
                        rewardRow(log)
                    }
                }
            }
        }
        .contentShape(.rect)
    }

    var reachedGlow: some View {
        RoundedRectangle(cornerRadius: corner.radius(24))
            .strokeBorder(Palette.accent, lineWidth: 1.5)
            .shadow(color: Palette.accent, radius: 10)
            .phaseAnimator([false, true]) { content, isLit in
                let opacity = isLit ? 1 : 0.3

                content
                    .opacity(opacity)
            } animation: { _ in
                .easeInOut(duration: 1.4)
            }
            .allowsHitTesting(false)
    }

    var billCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                SectionTitle("これからの引き落とし")

                Spacer()

                Text("合計 \(AmountText.text(model.upcomingBillTotal))")
                    .textFont(.caption)
                    .monospacedDigit()
                    .foregroundStyle(Palette.subtext)
            }

            VStack(spacing: 12) {
                ForEach(model.upcomingBills) { row in
                    Button {
                        onOpenRecurring(row.id)
                    } label: {
                        billRow(row)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(16)
        .card(cornerRadius: 24)
    }

    var trendLegend: some View {
        HStack(spacing: 16) {
            legend("手元のお金", dash: [])

            legend("純資産", dash: BalanceTrend.netWorthDash)
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
    }

    var netWorthRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("純資産")
                        .textFont(.caption)
                        .foregroundStyle(Palette.text)

                    Text("投資と借入も入れた額")
                        .textFont(.caption2)
                        .foregroundStyle(Palette.hint)
                }

                Spacer(minLength: 8)

                Text(AmountText.text(model.holdings.netWorth))
                    .displayFont(.headline)
                    .monospacedDigit()
                    .foregroundStyle(Palette.accentStrong)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
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

    func goalLine(_ goal: RewardGoal) -> some View {
        let remaining = model.remaining(to: goal)
        let progress = model.progress(to: goal)
        let note = remaining > 0 ? "あと \(AmountText.text(remaining))" : "届きました"

        return VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text("\(goal.name) まで")
                    .textFont(.caption)
                    .foregroundStyle(Palette.text)
                    .lineLimit(1)

                Spacer(minLength: 8)

                Text(note)
                    .textFont(.caption, weight: .semibold)
                    .monospacedDigit()
                    .foregroundStyle(Palette.accent)
            }

            RatioBar(progress, tint: Palette.accent, height: 6)
        }
    }

    func rewardRow(_ log: RewardLog) -> some View {
        let rule = model.rewardRule(for: log)
        let icon = rule.flatMap { model.rewardIcon(for: $0) }

        return HStack(spacing: 12) {
            IconBadge(icon, size: 26)

            Text(rule?.name ?? "")
                .textFont(.footnote)
                .foregroundStyle(Palette.text)
                .lineLimit(1)

            Spacer(minLength: 8)

            Text("\(log.date.month)/\(log.date.day)")
                .textFont(.caption2)
                .monospacedDigit()
                .foregroundStyle(Palette.subtext)

            Text("＋\(AmountText.text(log.amount))")
                .textFont(.footnote)
                .monospacedDigit()
                .foregroundStyle(Palette.accent)
        }
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

    func walletGroup(
        _ title: String,
        systemImage: String,
        sections: [AssetsModel.WalletSection]
    ) -> some View {
        let rows = sections.flatMap(\.rows)
        let total = rows.reduce(0) { $0 + $1.balance }

        return VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Image(systemName: systemImage)
                        .sansFont(.small, weight: .semibold)
                        .foregroundStyle(Palette.accent)
                        .frame(width: 26, height: 26)
                        .background(Palette.accent.opacity(.subtle), in: Circle())

                    Text(title)
                        .textFont(.subheadline, weight: .semibold)
                        .foregroundStyle(Palette.text)

                    Text("\(rows.count) 口座")
                        .textFont(.caption2)
                        .foregroundStyle(Palette.subtext)
                }

                Text(AmountText.text(total))
                    .displayFont(.title, weight: .bold)
                    .monospacedDigit()
                    .foregroundStyle(Palette.accentStrong)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
            .padding(.horizontal, 4)
            .padding(.top, 12)

            VStack(spacing: 0) {
                ForEach(sections) { section in
                    walletSection(section)
                        .overlay(alignment: .top) {
                            if section.id != sections.first?.id {
                                Hairline(thickness: 1)
                            }
                        }
                }
            }
            .padding(.horizontal, 16)
            .card(cornerRadius: 24)
        }
    }

    func walletSection(_ section: AssetsModel.WalletSection) -> some View {
        let total = section.rows.reduce(0) { $0 + $1.balance }

        return VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline) {
                Text(Self.title(of: section.role))
                    .textFont(.caption, weight: .semibold)
                    .foregroundStyle(Palette.subtext)

                Spacer(minLength: 8)

                Text(AmountText.text(total))
                    .textFont(.caption)
                    .monospacedDigit()
                    .foregroundStyle(Palette.subtext)
            }
            .padding(.top, 12)
            .padding(.bottom, 4)

            ForEach(section.rows) { row in
                Button {
                    onOpenWallet(row.wallet.id)
                } label: {
                    walletRow(row)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.bottom, 4)
    }

    func walletRow(_ row: AssetsModel.WalletRow) -> some View {
        let note = owedNote(of: row)

        return HStack(alignment: .top, spacing: 12) {
            IconBadge(row.icon, size: 32)

            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(row.wallet.name)
                        .textFont(.subheadline)
                        .foregroundStyle(Palette.text)
                        .lineLimit(1)

                    if let label = Self.label(of: row) {
                        Text(label)
                            .textFont(.caption2)
                            .foregroundStyle(Palette.subtext)
                            .lineLimit(1)
                    }

                    Spacer(minLength: 8)

                    Text(AmountText.text(row.balance))
                        .textFont(.subheadline, weight: .semibold)
                        .monospacedDigit()
                        .foregroundStyle(Self.amountColor(of: row))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }

                if row.repaidRatio != nil || note != nil {
                    HStack(spacing: 8) {
                        if let ratio = row.repaidRatio {
                            RatioBar(ratio, tint: Palette.accent, height: 4)
                        }

                        if let note {
                            Text(note)
                                .textFont(.caption2)
                                .monospacedDigit()
                                .foregroundStyle(Palette.subtext)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                                .fixedSize(horizontal: row.repaidRatio != nil, vertical: false)
                        }
                    }
                }
            }
            .frame(minHeight: 32)
        }
        .padding(.vertical, 8)
        .contentShape(.rect)
    }

    func billRow(_ row: AssetsModel.UpcomingBill) -> some View {
        HStack(alignment: .top, spacing: 16) {
            FlipDate(row.bill.date)

            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(row.title)
                            .textFont(.subheadline)
                            .foregroundStyle(Palette.text)
                            .lineLimit(2)

                        if let period = row.bill.period {
                            Text("\(RecurringText.period(period)) の利用分")
                                .textFont(.caption2)
                                .foregroundStyle(Palette.subtext)
                                .lineLimit(1)
                        }

                        if let moves = Self.movesText(of: row) {
                            Button {
                                movedBill = row
                            } label: {
                                HStack(spacing: 4) {
                                    Label(
                                        moves,
                                        systemImage: "arrow.uturn.right"
                                    )
                                    .lineLimit(2)

                                    Image(systemName: "chevron.right")
                                        .sansFont(.micro, weight: .bold)
                                }
                                .textFont(.caption2)
                                .foregroundStyle(Palette.accent)
                                .padding(.vertical, 4)
                                .contentShape(.rect)
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    Spacer(minLength: 8)

                    Text(AmountText.text(row.bill.amount))
                        .displayFont(.headline)
                        .monospacedDigit()
                        .foregroundStyle(Palette.accentStrong)
                        .lineLimit(1)
                }

                balanceBar(row.bill)

                HStack(alignment: .firstTextBaseline) {
                    Text(balanceText(row))
                        .textFont(.caption2)
                        .monospacedDigit()
                        .foregroundStyle(balanceColor(row.bill))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)

                    Spacer(minLength: 8)

                    Text(daysText(until: row.bill.date))
                        .textFont(.caption2)
                        .foregroundStyle(Palette.accent)
                }
            }
        }
        .padding(12)
        .background(
            Palette.accent.opacity(.faint),
            in: .rect(cornerRadius: corner.radius(20))
        )
        .contentShape(.rect)
    }

    func balanceBar(_ bill: CardBill) -> some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Palette.accent.opacity(.soft))

                Capsule()
                    .fill(balanceColor(bill))
                    .frame(width: proxy.size.width * Self.share(of: bill))
            }
        }
        .frame(height: 4)
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

    static func title(of role: Wallet.Kind.Role) -> String {
        switch role {
        case .onHand: "手持ち"
        case .card: "カードの未払い"
        case .investment: "投資"
        case .loan: "借入"
        }
    }

    static func label(of row: AssetsModel.WalletRow) -> String? {
        switch row.wallet.kind.role {
        case .card: row.balance > 0 ? "返ってくる額" : "未払い"
        case .loan: "残り"
        case .onHand, .investment: nil
        }
    }

    static func amountColor(of row: AssetsModel.WalletRow) -> Color {
        switch row.wallet.kind.role {
        case .card: row.balance > 0 ? Palette.accent : Palette.text
        case .loan: Palette.text
        case .onHand, .investment:
            row.balance < 0 ? Palette.rose : Palette.accentStrong
        }
    }

    static func repaymentText(_ repayment: AssetsModel.Repayment) -> String {
        switch repayment {
        case .unset: "返済は未設定"
        case .finished: "返し終わりました"
        case .open: "返し終わる時期は未定"
        case let .until(payoff): payoffText(payoff)
        }
    }

    static func payoffText(_ payoff: LoanPayoff) -> String {
        let date = payoff.lastDate
        return "あと \(payoff.count) 回・\(String(date.year))/\(date.month) まで"
    }

    static func movesText(of row: AssetsModel.UpcomingBill) -> String? {
        let movedIn = row.movedIn.count
        let movedOut = row.movedOut.count
        let inText = movedIn > 0 ? ["前から \(movedIn) 件"] : []
        let outText = movedOut > 0 ? ["後へ \(movedOut) 件"] : []
        let parts = inText + outText

        return parts.isEmpty ? nil : parts.joined(separator: "・")
    }

    static func share(of bill: CardBill) -> CGFloat {
        guard bill.balanceBefore > 0 else {
            return 1
        }

        let share = Double(bill.amount) / Double(bill.balanceBefore)

        return CGFloat(min(share, 1))
    }

    func owedNote(of row: AssetsModel.WalletRow) -> String? {
        if let repayment = row.repayment {
            let text = Self.repaymentText(repayment)

            guard let ratio = row.repaidRatio else {
                return text
            }

            return "\(Int((ratio * 100).rounded(.down)))%・\(text)"
        }

        guard row.wallet.kind == .card else {
            return nil
        }

        return row.nextBill.map(nextBillText) ?? "引き落としは未設定"
    }

    func nextBillText(_ bill: CardBill) -> String {
        let date = "\(bill.date.month)/\(bill.date.day)"
        return "\(date) に引き落とし・\(daysText(until: bill.date))"
    }

    func openPendingEntry() {
        guard let pendingEntry else {
            return
        }

        self.pendingEntry = nil

        onOpenEntry(pendingEntry)
    }

    func balanceText(_ row: AssetsModel.UpcomingBill) -> String {
        let source = row.source ?? "口座"
        let bill = row.bill

        guard bill.shortage == 0 else {
            return "\(source)が \(AmountText.text(bill.shortage)) 足りません"
        }

        let before = AmountText.text(bill.balanceBefore)
        let after = AmountText.text(bill.balanceAfter)

        return "\(source) \(before) → \(after)"
    }

    func balanceColor(_ bill: CardBill) -> Color {
        bill.shortage > 0 ? Palette.rose : Palette.accent
    }

    func daysText(until date: LocalDate) -> String {
        let days = model.today.days(until: date)
        return days == 1 ? "明日" : "あと \(days) 日"
    }

    func monthColor(_ month: YearMonth) -> Color {
        month == model.currentMonth ? Palette.accent : Palette.hint
    }
}

private struct BalanceTrend: View {
    static let netWorthDash: [CGFloat] = [4, 3]

    let totals: [Int]
    let netWorths: [Int]?

    var body: some View {
        GeometryReader { proxy in
            let points = points(of: totals, in: proxy.size)

            let netWorthPoints = netWorths.map { values in
                self.points(of: values, in: proxy.size)
            }

            ZStack {
                if let netWorthPoints {
                    Path { path in
                        path.addLines(netWorthPoints)
                    }
                    .stroke(
                        Palette.accent.opacity(.strong),
                        style: StrokeStyle(
                            lineWidth: 1.2,
                            lineJoin: .round,
                            dash: Self.netWorthDash
                        )
                    )
                }

                Path { path in
                    path.addLines(points)
                }
                .stroke(
                    Palette.accent,
                    style: StrokeStyle(lineWidth: 1.6, lineJoin: .round)
                )

                ForEach(points.indices, id: \.self) { index in
                    let isLast = index == points.count - 1
                    let size: CGFloat = isLast ? 8 : 4
                    let color = isLast ? Palette.accentStrong : Palette.accent

                    Circle()
                        .fill(color)
                        .frame(width: size, height: size)
                        .position(points[index])
                }
            }
        }
    }

    func points(
        of values: [Int],
        in size: CGSize
    ) -> [CGPoint] {
        let all = totals + (netWorths ?? [])
        let low = all.min() ?? 0
        let high = all.max() ?? 0
        let range = CGFloat(max(high - low, 1))
        let step = size.width / CGFloat(max(values.count, 1))
        let inset: CGFloat = 6

        return values.enumerated().map { index, total in
            let ratio = high == low ? 0.5 : CGFloat(total - low) / range
            let x = step * (CGFloat(index) + 0.5)
            let y = inset + (size.height - inset * 2) * (1 - ratio)

            return CGPoint(x: x, y: y)
        }
    }
}
