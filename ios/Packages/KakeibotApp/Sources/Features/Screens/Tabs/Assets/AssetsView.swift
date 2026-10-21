import Core
import DesignSystem
import SwiftUI

public struct AssetsView: View {
    @Bindable private var model: AssetsModel

    @Environment(\.themeStyle.corner) private var corner

    private let onTransfer: () -> Void
    private let onOpenWallet: (Wallet.ID) -> Void
    private let onOpenRecurring: (Recurring.ID) -> Void

    public init(
        model: AssetsModel,
        onTransfer: @escaping () -> Void,
        onOpenWallet: @escaping (Wallet.ID) -> Void,
        onOpenRecurring: @escaping (Recurring.ID) -> Void
    ) {
        self.model = model
        self.onTransfer = onTransfer
        self.onOpenWallet = onOpenWallet
        self.onOpenRecurring = onOpenRecurring
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                header
                totalCard

                if !model.upcomingBills.isEmpty {
                    billCard
                }

                ForEach(model.sections) { section in
                    walletSection(section)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .errorBanner(model.errorNotice) {
            model.errorNotice.clear()
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
        VStack(alignment: .leading, spacing: 10) {
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

            VStack(spacing: 10) {
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
        HStack(spacing: 14) {
            legend("手元のお金", dash: [])
            legend("純資産", dash: BalanceTrend.netWorthDash)
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
    }

    func legend(
        _ title: String,
        dash: [CGFloat]
    ) -> some View {
        HStack(spacing: 6) {
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

    var netWorthRow: some View {
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
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(
            Palette.accent.opacity(.faint),
            in: .rect(cornerRadius: corner.radius(14))
        )
    }

    func walletSection(_ section: AssetsModel.WalletSection) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionTitle(Self.title(of: section.role))
                .padding(.horizontal, 4)
                .padding(.top, 4)

            LazyVGrid(columns: Self.columns, spacing: 8) {
                ForEach(section.rows) { row in
                    Button {
                        onOpenWallet(row.wallet.id)
                    } label: {
                        walletTile(row)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    func billRow(_ row: AssetsModel.UpcomingBill) -> some View {
        HStack(alignment: .top, spacing: 14) {
            dateChip(row.bill.date)

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
            in: .rect(cornerRadius: corner.radius(18))
        )
        .contentShape(.rect)
    }

    func dateChip(_ date: LocalDate) -> some View {
        VStack(spacing: 0) {
            Text("\(date.month)月")
                .textFont(.caption2)
                .foregroundStyle(Palette.backgroundBottom)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 2)
                .background(Palette.accent)

            Text("\(date.day)")
                .displayFont(.title)
                .monospacedDigit()
                .foregroundStyle(Palette.text)
                .padding(.top, 2)

            Text(date.weekday.shortName)
                .textFont(.caption2)
                .foregroundStyle(date.tint ?? Palette.subtext)
                .padding(.bottom, 4)
        }
        .frame(width: 52)
        .background(Palette.panel)
        .clipShape(.rect(cornerRadius: corner.radius(12)))
        .overlay {
            RoundedRectangle(cornerRadius: corner.radius(12))
                .stroke(Palette.outline, lineWidth: 1)
        }
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

    func walletTile(_ row: AssetsModel.WalletRow) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                IconImage(row.icon, size: 15)
                    .foregroundStyle(Palette.accent)

                Text(row.wallet.name)
                    .textFont(.caption)
                    .foregroundStyle(Palette.text)
                    .lineLimit(1)

                Spacer(minLength: 4)

                if let label = Self.label(of: row) {
                    Text(label)
                        .textFont(.caption2)
                        .foregroundStyle(Palette.subtext)
                        .lineLimit(1)
                }
            }

            Text(AmountText.text(Self.shownAmount(of: row)))
                .displayFont(.headline)
                .monospacedDigit()
                .foregroundStyle(Self.amountColor(of: row))
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            if let note = note(of: row) {
                Text(note)
                    .textFont(.caption2)
                    .monospacedDigit()
                    .foregroundStyle(Palette.subtext)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, minHeight: 74, alignment: .leading)
        .card(cornerRadius: 18)
        .contentShape(.rect)
    }
}

private extension AssetsView {
    static let columns = Array(
        repeating: GridItem(.flexible(), spacing: 8),
        count: 2
    )

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

    static func shownAmount(of row: AssetsModel.WalletRow) -> Int {
        switch row.wallet.kind.role {
        case .card, .loan: abs(row.balance)
        case .onHand, .investment: row.balance
        }
    }

    static func amountColor(of row: AssetsModel.WalletRow) -> Color {
        switch row.wallet.kind.role {
        case .card: row.balance > 0 ? Palette.accent : Palette.accentStrong
        case .loan: Palette.text
        case .onHand, .investment:
            row.balance < 0 ? Palette.rose : Palette.accentStrong
        }
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

    func note(of row: AssetsModel.WalletRow) -> String? {
        if let repayment = row.repayment {
            return Self.repaymentText(repayment)
        }

        guard row.wallet.kind == .card else {
            return nil
        }

        return row.nextBill.map(nextBillText) ?? "引き落としは未設定"
    }

    func nextBillText(_ bill: CardBill) -> String {
        let date = "\(bill.date.month)/\(bill.date.day)"
        return "\(date) に \(AmountText.text(bill.amount)) 引き落とし"
    }

    var changeText: String {
        let change = model.changeFromLastMonth
        let sign = change > 0 ? "+" : ""
        return "先月末より \(sign)\(AmountText.text(change))"
    }

    static func share(of bill: CardBill) -> CGFloat {
        guard bill.balanceBefore > 0 else {
            return 1
        }

        let share = Double(bill.amount) / Double(bill.balanceBefore)
        return CGFloat(min(share, 1))
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
