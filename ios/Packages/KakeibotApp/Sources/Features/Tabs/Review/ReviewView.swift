import Core
import DesignSystem
import SwiftUI

struct ReviewView: View {
    @Bindable var model: ReviewModel

    @State private var openShare: ReviewModel.Share?

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                header

                VStack(alignment: .leading, spacing: 8) {
                    CapsulePicker(
                        selection: kindBinding,
                        options: Self.kindOptions
                    )

                    CapsulePicker(
                        selection: scaleBinding,
                        options: Self.scaleOptions
                    )
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                ZStack(alignment: .top) {
                    content
                        .id(model.period)
                        .transition(.page(forward: model.isMovingForward))
                }

                if let errorMessage = model.errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(Palette.rose)
                }
            }
            .padding(.horizontal, 14)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .onPageSwipe { direction in
            move(direction)
        }
        .sensoryFeedback(.selection, trigger: model.period)
        .sheet(item: $openShare) { share in
            ReviewShareSheet(
                share: share,
                periodTitle: periodTitle,
                rows: model.rows(for: share)
            )
        }
        .background {
            Rectangle()
                .fill(Palette.night)
                .ignoresSafeArea()
        }
    }
}

private extension ReviewView {
    var header: some View {
        HStack {
            Text("振り返り")
                .font(.system(size: 15, design: .serif))
                .tracking(3)
                .foregroundStyle(Palette.gold)

            Spacer()

            periodButton(systemImage: "chevron.left", count: -1)

            VStack(spacing: 1) {
                Text(periodTitle)
                    .font(.system(size: 15, design: .serif))
                    .foregroundStyle(Palette.champagne)
                    .contentTransition(periodTextTransition)

                if let periodSubtitle {
                    Text(periodSubtitle)
                        .font(.system(size: 10))
                        .monospacedDigit()
                        .foregroundStyle(Palette.mist)
                        .contentTransition(periodTextTransition)
                }
            }

            periodButton(systemImage: "chevron.right", count: 1)
                .disabled(!model.canMoveForward)
        }
    }

    var content: some View {
        VStack(spacing: 12) {
            totalCard

            if model.kind != .balance {
                sharesCard(
                    "カテゴリごと",
                    shares: model.categoryShares,
                    showsChart: true
                )

                sharesCard(
                    "口座ごと",
                    shares: model.walletShares,
                    showsChart: false
                )
            }
        }
    }

    var totalCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionTitle(totalTitle)

            Text(AmountText.text(model.total))
                .font(.system(size: 32, weight: .bold, design: .serif))
                .monospacedDigit()
                .foregroundStyle(Palette.champagne)

            Text(comparisonText)
                .font(.footnote)
                .foregroundStyle(Palette.mist)

            if model.kind == .balance {
                VStack(spacing: 6) {
                    balanceLine("収入", amount: model.summary.income.total)
                    balanceLine("支出", amount: model.summary.expense.total)
                }
                .padding(.top, 4)
            }

            if let usage = model.budgetUsage {
                VStack(spacing: 6) {
                    HStack {
                        Text("予算 \(AmountText.text(usage.budget))")
                        Spacer()
                        Text(usage.remainingText)
                    }
                    .font(.caption)
                    .monospacedDigit()
                    .foregroundStyle(Palette.mist)

                    UsageBar(usage)
                }
                .padding(.top, 4)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .card()
    }

    func periodButton(
        systemImage: String,
        count: Int
    ) -> some View {
        Button {
            withAnimation(.snappy) {
                model.move(by: count)
            }
        } label: {
            Image(systemName: systemImage)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Palette.mist)
                .frame(width: 40, height: 44)
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }

    func balanceLine(
        _ title: String,
        amount: Int
    ) -> some View {
        HStack {
            Text(title)
                .font(.caption)
                .foregroundStyle(Palette.mist)

            Spacer()

            Text(AmountText.text(amount))
                .font(.system(size: 15, design: .serif))
                .monospacedDigit()
                .foregroundStyle(Palette.ink)
        }
    }

    func sharesCard(
        _ title: String,
        shares: [ReviewModel.Share],
        showsChart: Bool
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(title)

            if shares.isEmpty {
                Text("この期間の記録はありません")
                    .font(.footnote)
                    .foregroundStyle(Palette.mist)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
            } else {
                if showsChart {
                    DonutChart(Self.slices(shares))
                        .frame(width: 180, height: 180)
                        .overlay {
                            chartCenter
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 4)
                }

                ForEach(shares) { share in
                    shareRow(share)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .card()
    }

    var chartCenter: some View {
        VStack(spacing: 2) {
            Text(totalTitle)
                .font(.caption2)
                .foregroundStyle(Palette.mist)

            Text(AmountText.text(model.total))
                .font(.system(size: 17, design: .serif))
                .monospacedDigit()
                .foregroundStyle(Palette.champagne)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .padding(.horizontal, 36)
    }

    func shareRow(_ share: ReviewModel.Share) -> some View {
        Button {
            openShare = share
        } label: {
            shareLabel(share)
        }
        .buttonStyle(.plain)
    }

    func shareLabel(_ share: ReviewModel.Share) -> some View {
        VStack(spacing: 6) {
            HStack(spacing: 10) {
                IconBadge(share.icon, size: 30)

                Text(share.name)
                    .font(.subheadline)
                    .foregroundStyle(Palette.ink)
                    .lineLimit(1)

                Text(Self.percentText(share.ratio))
                    .font(.caption)
                    .monospacedDigit()
                    .foregroundStyle(Palette.mist)

                Spacer(minLength: 8)

                Text(AmountText.text(share.amount))
                    .font(.system(size: 15, design: .serif))
                    .monospacedDigit()
                    .foregroundStyle(Palette.champagne)

                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundStyle(Palette.dusk)
            }

            if let usage = share.usage {
                UsageBar(usage)
                    .padding(.leading, 40)
            }
        }
    }
}

private extension ReviewView {
    static let kindOptions: [CapsulePicker<ReviewKind>.Option] = [
        .init("支出", value: .expense),
        .init("収入", value: .income),
        .init("収支", value: .balance)
    ]

    static let scaleOptions: [CapsulePicker<ReviewPeriod.Scale>.Option] = [
        .init("週", value: .week),
        .init("月", value: .month),
        .init("年", value: .year)
    ]

    var kindBinding: Binding<ReviewKind> {
        Binding {
            model.kind
        } set: { kind in
            Task {
                await model.setKind(kind)
            }
        }
    }

    var scaleBinding: Binding<ReviewPeriod.Scale> {
        Binding {
            model.scale
        } set: { scale in
            Task {
                await model.setScale(scale)
            }
        }
    }

    var periodTextTransition: ContentTransition {
        .numericText(countsDown: !model.isMovingForward)
    }

    var periodTitle: String {
        let range = model.period.range
        let month = range.upperBound.yearMonth

        switch model.scale {
        case .week: return PeriodText.range(range)
        case .month: return "\(String(month.year))年 \(month.month)月"
        case .year: return "\(String(month.year))年"
        }
    }

    var periodSubtitle: String? {
        switch model.scale {
        case .week: nil
        case .month, .year: PeriodText.range(model.period.range)
        }
    }

    var totalTitle: String {
        switch model.kind {
        case .expense: "支出の合計"
        case .income: "収入の合計"
        case .balance: "収支"
        }
    }

    var comparisonText: String {
        let previous = Self.previousName(of: model.scale)
        let change = model.change
        let amount = AmountText.text(abs(change))

        if change > 0 {
            return "\(previous)より \(amount) 多い"
        }

        if change < 0 {
            return "\(previous)より \(amount) 少ない"
        }

        return "\(previous)と同じ"
    }

    static func previousName(of scale: ReviewPeriod.Scale) -> String {
        switch scale {
        case .week: "前の週"
        case .month: "前の月"
        case .year: "前の年"
        }
    }

    static func percentText(_ ratio: Double) -> String {
        "\(Int((ratio * 100).rounded()))%"
    }

    static func slices(
        _ shares: [ReviewModel.Share]
    ) -> [DonutChart<AnyHashable>.Slice] {
        shares.map { share in
            let color = share.icon.flatMap { Color(hex: $0.color) }

            return DonutChart.Slice(
                id: share.id,
                value: share.amount,
                color: color ?? Palette.gold
            )
        }
    }

    func move(_ direction: PageSwipeDirection) {
        let count = direction == .forward ? 1 : -1

        withAnimation(.snappy) {
            model.move(by: count)
        }
    }
}
