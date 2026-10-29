import Core
import DesignSystem
import SwiftUI

extension AssetsView {
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
        .card()
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
            .card()
        }
    }
}

private extension AssetsView {
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
        .sharesTextScale(id: section.rows.map(\.wallet.name))
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
                        .sharedTextScale()

                    if let label = Self.label(of: row) {
                        Text(label)
                            .textFont(.caption2)
                            .foregroundStyle(Palette.subtext)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
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
                                .minimumScaleFactor(0.8)
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
                        .minimumScaleFactor(0.8)
                }

                balanceBar(row.bill)

                VStack(alignment: .leading, spacing: 2) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(row.source ?? "口座")
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)

                        Spacer(minLength: 8)

                        Text(daysText(until: row.bill.date))
                            .foregroundStyle(Palette.accent)
                    }

                    Text(balanceText(row.bill))
                        .monospacedDigit()
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                .textFont(.caption2)
                .foregroundStyle(balanceColor(row.bill))
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
        let clamped = min(share, 1)

        return CGFloat(clamped)
    }

    func owedNote(of row: AssetsModel.WalletRow) -> String? {
        if let repayment = row.repayment {
            let text = Self.repaymentText(repayment)

            guard let percent = row.repaidPercent else {
                return text
            }

            return "\(percent)%・\(text)"
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

    func balanceText(_ bill: CardBill) -> String {
        guard bill.shortage == 0 else {
            return "\(AmountText.text(bill.shortage)) 足りません"
        }

        let before = AmountText.text(bill.balanceBefore)
        let after = AmountText.text(bill.balanceAfter)

        return "\(before) → \(after)"
    }

    func balanceColor(_ bill: CardBill) -> Color {
        bill.shortage > 0 ? Palette.rose : Palette.accent
    }

    func daysText(until date: LocalDate) -> String {
        let days = model.today.days(until: date)
        return days == 1 ? "明日" : "あと \(days) 日"
    }
}
