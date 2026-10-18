import Core
import DesignSystem
import SwiftUI

public struct ReviewView: View {
    @Bindable private var model: ReviewModel

    @State private var openShare: ReviewModel.Share?
    @State private var pendingEntry: Entry.ID?
    @State private var slide = PageSlide()

    private let onOpenEntry: (Entry.ID) -> Void

    public init(
        model: ReviewModel,
        onOpenEntry: @escaping (Entry.ID) -> Void
    ) {
        self.model = model
        self.onOpenEntry = onOpenEntry
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                header
                periodBar

                content
                    .pageSlide(slide)

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
        .sensoryFeedback(.selection, trigger: model.kind)
        .sheet(item: $openShare, onDismiss: openPendingEntry) { share in
            ReviewShareSheet(
                share: share,
                periodTitle: periodTitle,
                rows: model.rows(for: share)
            ) { id in
                pendingEntry = id
                openShare = nil
            }
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

            CapsulePicker(
                selection: scaleBinding,
                options: Self.scaleOptions
            )
        }
    }

    var periodBar: some View {
        HStack {
            periodButton(systemImage: "chevron.left", count: -1)

            Spacer()

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

            Spacer()

            periodButton(systemImage: "chevron.right", count: 1)
                .disabled(!model.canMoveForward)
        }
    }

    var content: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                ForEach(ReviewKind.allCases, id: \.self) { kind in
                    kindTile(kind)
                }
            }

            detailCard

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

    var detailCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: Self.changeImage(model.change))
                    .font(.caption)
                    .foregroundStyle(selectedChangeColor)

                Text(comparisonText)
                    .font(.footnote)
                    .foregroundStyle(Palette.ink)
            }

            if model.kind == .balance {
                VStack(spacing: 10) {
                    balanceBar(
                        "収入",
                        amount: model.summary.income.total,
                        tint: Palette.gold
                    )

                    balanceBar(
                        "支出",
                        amount: model.summary.expense.total,
                        tint: Palette.rose
                    )
                }
                .padding(.top, 6)
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
            move(by: count)
        } label: {
            Image(systemName: systemImage)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Palette.mist)
                .frame(width: 40, height: 44)
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }

    func balanceBar(
        _ title: String,
        amount: Int,
        tint: Color
    ) -> some View {
        VStack(spacing: 5) {
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

            RatioBar(balanceRatio(of: amount), tint: tint, height: 6)
        }
    }

    func kindTile(_ kind: ReviewKind) -> some View {
        let isSelected = kind == model.kind
        let fill = isSelected ? Palette.gold.opacity(0.14) : Color.clear
        let rim = isSelected ? Palette.gold : Palette.gold.opacity(0.2)
        let titleColor = isSelected ? Palette.gold : Palette.mist
        let amountColor = isSelected ? Palette.champagne : Palette.ink
        let change = model.change(of: kind)

        return Button {
            withAnimation(.snappy) {
                model.setKind(kind)
            }

            Task {
                await model.saveSelection()
            }
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Text(Self.title(of: kind))
                        .font(.caption)
                        .foregroundStyle(titleColor)

                    Spacer(minLength: 0)

                    Image(systemName: Self.changeImage(change))
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(Self.changeColor(change, of: kind))
                }

                Text(AmountText.text(model.total(of: kind)))
                    .font(.system(size: 17, design: .serif))
                    .monospacedDigit()
                    .foregroundStyle(amountColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(fill, in: RoundedRectangle(cornerRadius: 16))
            .overlay {
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(rim, lineWidth: 1)
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
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
                    DonutChart(Self.slices(shares)) { id in
                        openShare = shares.first { $0.id == id }
                    }
                    .frame(width: 180, height: 180)
                    .overlay {
                        chartCenter
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)

                    if let others = Self.otherShares(shares) {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(Palette.dusk)
                                .frame(width: 8, height: 8)

                            Text("その他 \(others.count) 件")
                                .font(.caption)
                                .foregroundStyle(Palette.mist)
                        }
                        .frame(maxWidth: .infinity)
                    }
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
    static let chartLimit = 5
    static let minorRatio = 0.05

    static let scaleOptions: [CapsulePicker<ReviewPeriod.Scale>.Option] = [
        .init("週", value: .week),
        .init("月", value: .month),
        .init("年", value: .year)
    ]

    var scaleBinding: Binding<ReviewPeriod.Scale> {
        Binding {
            model.scale
        } set: { scale in
            let scales = ReviewPeriod.Scale.allCases
            let from = scales.firstIndex(of: model.scale) ?? 0
            let to = scales.firstIndex(of: scale) ?? 0

            PageSlide.run($slide, forward: to > from) {
                model.setScale(scale)
            }

            Task {
                await model.saveSelection()
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
        Self.title(of: model.kind)
    }

    var selectedChangeColor: Color {
        Self.changeColor(model.change, of: model.kind)
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

    static func changeImage(_ change: Int) -> String {
        if change > 0 {
            return "arrow.up.right"
        }

        return change < 0 ? "arrow.down.right" : "equal"
    }

    static func changeColor(
        _ change: Int,
        of kind: ReviewKind
    ) -> Color {
        guard change != 0 else {
            return Palette.mist
        }

        let isGood = kind == .expense ? change < 0 : change > 0
        return isGood ? Palette.gold : Palette.rose
    }

    static func title(of kind: ReviewKind) -> String {
        switch kind {
        case .expense: "支出"
        case .income: "収入"
        case .balance: "収支"
        }
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

    static func otherShares(
        _ shares: [ReviewModel.Share]
    ) -> [ReviewModel.Share]? {
        let main = shares
            .prefix(chartLimit)
            .prefix(while: { $0.ratio >= minorRatio })

        let others = Array(shares.dropFirst(main.count))
        return others.count > 1 ? others : nil
    }

    static func slices(
        _ shares: [ReviewModel.Share]
    ) -> [DonutChart<AnyHashable>.Slice] {
        let others = otherShares(shares) ?? []
        let main = shares.dropLast(others.count)

        let slices = main.map { share in
            let color = share.icon.flatMap { Color(hex: $0.color) }

            return DonutChart<AnyHashable>.Slice(
                id: share.id,
                value: share.amount,
                color: color ?? Palette.gold
            )
        }

        guard !others.isEmpty else {
            return slices
        }

        let other = DonutChart<AnyHashable>.Slice(
            id: "others",
            value: others.reduce(0) { $0 + $1.amount },
            color: Palette.dusk
        )

        return slices + [other]
    }

    func balanceRatio(of amount: Int) -> Double {
        let income = model.summary.income.total
        let expense = model.summary.expense.total
        let largest = max(income, expense)
        return largest > 0 ? Double(amount) / Double(largest) : 0
    }

    func openPendingEntry() {
        guard let pendingEntry else {
            return
        }

        self.pendingEntry = nil
        onOpenEntry(pendingEntry)
    }

    func move(_ direction: PageSwipeDirection) {
        move(by: direction == .forward ? 1 : -1)
    }

    func move(by count: Int) {
        guard model.canMove(by: count) else {
            return
        }

        PageSlide.run($slide, forward: count > 0) {
            model.move(by: count)
        }
    }
}
