import Core
import DesignSystem
import SwiftUI

extension AssetsView {
    var billCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            CardHeader(
                "これからの引き落とし",
                note: "合計 \(AmountText.text(model.upcomingBillTotal))"
            )

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
            .sharesTextScale(id: model.upcomingBills.map(\.source))
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
        .card()
    }

    func walletGroup(
        _ title: String,
        sections: [AssetsModel.WalletSection],
        onAdd: (() -> Void)? = nil
    ) -> some View {
        let rows = sections.flatMap(\.rows)
        let total = rows.reduce(0) { $0 + $1.balance }
        let note = "\(rows.count) 口座 · \(AmountText.text(total))"

        return VStack(alignment: .leading, spacing: 0) {
            CardHeader(title, note: rows.isEmpty ? nil : note)

            if rows.isEmpty {
                Text("口座を追加すると、ここに並びます")
                    .textFont(.footnote)
                    .foregroundStyle(Palette.subtext)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.bottom, 8)
            }

            ForEach(sections) { section in
                walletSection(section)
                    .overlay(alignment: .top) {
                        Hairline(thickness: 1)
                    }
            }

            if let onAdd {
                addWalletRow(action: onAdd)
                    .overlay(alignment: .top) {
                        Hairline(thickness: 1)
                    }
            }
        }
        .padding(.horizontal, 16)
        .card()
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

                if section.rows.count > 1 {
                    Text(AmountText.text(total))
                        .textFont(.footnote, weight: .semibold)
                        .monospacedDigit()
                        .foregroundStyle(Palette.subtext)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
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
        HStack(alignment: .top, spacing: 12) {
            IconBadge(row.icon, size: 32)

            VStack(alignment: .leading, spacing: 4) {
                ViewThatFits(in: .horizontal) {
                    walletLine(row)

                    walletLines(row)
                }

                debtDetail(of: row)

                if row.needsAdjustment {
                    adjustNotice(of: row)
                }
            }
            .frame(minHeight: 32)

            Image(systemName: "chevron.right")
                .sansFont(.small)
                .foregroundStyle(Palette.hint)
                .frame(height: 32)
        }
        .padding(.vertical, 8)
        .contentShape(.rect)
    }

    func walletLine(_ row: AssetsModel.WalletRow) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            walletName(row)

            if let label = Self.label(of: row) {
                walletLabel(label)
            }

            Spacer(minLength: 8)

            walletBalance(row)
                .fixedSize()
                .layoutPriority(1)
        }
    }

    func walletLines(_ row: AssetsModel.WalletRow) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            walletName(row)

            HStack(alignment: .firstTextBaseline, spacing: 8) {
                if let label = Self.label(of: row) {
                    walletLabel(label)
                }

                Spacer(minLength: 8)

                walletBalance(row)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .layoutPriority(1)
            }
        }
    }

    func walletName(_ row: AssetsModel.WalletRow) -> some View {
        Text(row.wallet.name)
            .textFont(.subheadline)
            .foregroundStyle(Palette.text)
            .sharedTextScale()
    }

    func walletLabel(_ label: String) -> some View {
        Text(label)
            .textFont(.caption2)
            .foregroundStyle(Palette.subtext)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
    }

    func walletBalance(_ row: AssetsModel.WalletRow) -> some View {
        Text(AmountText.text(row.balance))
            .textFont(.subheadline, weight: .semibold)
            .monospacedDigit()
            .foregroundStyle(Self.amountColor(of: row))
    }

    func addWalletRow(action: @escaping () -> Void) -> some View {
        let shape = RoundedRectangle(cornerRadius: corner.radius(32 * 0.3), style: .continuous)

        return Button(action: action) {
            HStack(spacing: 12) {
                shape
                    .fill(Palette.faint)
                    .overlay {
                        shape
                            .stroke(Palette.outline, style: .dashed)
                    }
                    .overlay {
                        Image(systemName: "plus")
                            .sansFont(.small, weight: .semibold)
                            .foregroundStyle(Palette.accent)
                    }
                    .frame(width: 32, height: 32)

                VStack(alignment: .leading, spacing: 2) {
                    Text("新しい口座を追加")
                        .textFont(.subheadline, weight: .semibold)
                        .foregroundStyle(Palette.accentStrong)

                    Text("現金・銀行・カードなど")
                        .textFont(.caption2)
                        .foregroundStyle(Palette.subtext)
                }
                .lineLimit(1)

                Spacer(minLength: 8)

                Image(systemName: "chevron.right")
                    .sansFont(.small)
                    .foregroundStyle(Palette.hint)
            }
            .padding(.vertical, 12)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }

    func adjustNotice(of row: AssetsModel.WalletRow) -> some View {
        ViewThatFits(in: .horizontal) {
            adjustLine(row, showsText: true)

            adjustLine(row, showsText: false)
        }
    }

    func adjustLine(
        _ row: AssetsModel.WalletRow,
        showsText: Bool
    ) -> some View {
        HStack(spacing: 8) {
            Group {
                if showsText {
                    Label("手持ちがマイナスです", systemImage: "exclamationmark.circle")
                } else {
                    Image(systemName: "exclamationmark.circle")
                }
            }
            .textFont(.caption)
            .foregroundStyle(Palette.rose)
            .fixedSize()

            Spacer(minLength: 8)

            ChipButton("残高を合わせる", systemImage: "equal") {
                adjusting = row
            }
            .fixedSize()
        }
    }

    func billRow(_ row: AssetsModel.UpcomingBill) -> some View {
        BillRow(
            row.bill,
            title: row.title,
            source: row.source,
            today: model.today,
            style: .detailed
        ) {
            if let moves = Self.movesText(of: row) {
                Button {
                    entrySheet = .moved(row)
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
    }
}

private extension AssetsView {
    @ViewBuilder
    func debtDetail(of row: AssetsModel.WalletRow) -> some View {
        if row.wallet.kind == .card,
           let bill = row.nextBill {
            AssetsDebtChip(systemImage: "calendar", text: nextBillText(bill))

            if let unpaid = row.unpaid {
                Button {
                    entrySheet = .unpaid(unpaid, of: row, bill: bill)
                } label: {
                    HStack(spacing: 4) {
                        Label(
                            "未払いの記録を見る（\(unpaid.count) 件）",
                            systemImage: "list.bullet"
                        )
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)

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

        if let ratio = row.repaidRatio,
           let percent = row.repaidPercent {
            HStack(spacing: 8) {
                RatioBar(ratio, tint: Palette.accent)

                Text("\(percent)% 返した")
                    .textFont(.caption)
                    .monospacedDigit()
                    .foregroundStyle(Palette.subtext)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .fixedSize()
            }
        }

        if case let .until(payoff) = row.repayment {
            AssetsDebtChip(
                systemImage: "arrow.triangle.2.circlepath",
                text: Self.payoffText(payoff)
            )
        } else if let note = plainNote(of: row) {
            Text(note)
                .textFont(.caption)
                .foregroundStyle(Palette.subtext)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
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

    static func repaymentText(_ repayment: AssetsModel.Repayment) -> String? {
        switch repayment {
        case .unset: "返済は未設定"
        case .finished: "返し終わりました"
        case .open: "返し終わる時期は未定"
        case .until: nil
        }
    }

    static func payoffText(_ payoff: LoanPayoff) -> String {
        let date = payoff.lastDate
        return "あと \(payoff.count) 回 · \(String(date.year))/\(date.month) まで"
    }

    static func movesText(of row: AssetsModel.UpcomingBill) -> String? {
        let movedIn = row.movedIn.count
        let movedOut = row.movedOut.count
        let inText = movedIn > 0 ? ["前から \(movedIn) 件"] : []
        let outText = movedOut > 0 ? ["後へ \(movedOut) 件"] : []
        let parts = inText + outText
        return parts.isEmpty ? nil : parts.joined(separator: "・")
    }

    func plainNote(of row: AssetsModel.WalletRow) -> String? {
        if let repayment = row.repayment {
            return Self.repaymentText(repayment)
        }

        guard
            row.wallet.kind == .card,
            row.nextBill == nil
        else {
            return nil
        }

        return "引き落としは未設定"
    }

    func nextBillText(_ bill: CardBill) -> String {
        let date = "\(bill.date.month)/\(bill.date.day)"
        let weekday = bill.date.weekday.shortName
        let days = BillText.days(until: bill.date, today: model.today)
        return "\(date)（\(weekday)）引き落とし · \(days)"
    }
}
