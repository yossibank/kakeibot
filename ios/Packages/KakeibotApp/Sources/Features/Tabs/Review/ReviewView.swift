import Core
import DesignSystem
import Store
import SwiftUI

public struct ReviewView: View {
    @Bindable private var model: ReviewModel

    @State private var openShare: ReviewModel.Share?
    @State private var pendingEntry: Entry.ID?
    @State private var pendingRecurring: Recurring.ID?
    @State private var openStamp: StampCalendar.Tally?
    @State private var pendingDay: LocalDate?
    @State private var slide = PageSlide()

    private let onOpenEntry: (Entry.ID) -> Void
    private let onOpenRecurring: (Recurring.ID) -> Void
    private let onOpenDay: (LocalDate) -> Void

    public init(
        model: ReviewModel,
        onOpenEntry: @escaping (Entry.ID) -> Void,
        onOpenRecurring: @escaping (Recurring.ID) -> Void,
        onOpenDay: @escaping (LocalDate) -> Void
    ) {
        self.model = model
        self.onOpenEntry = onOpenEntry
        self.onOpenRecurring = onOpenRecurring
        self.onOpenDay = onOpenDay
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                header
                periodBar

                content
                    .pageSlide(slide)
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
                choose(id, in: share)
            }
        }
        .sheet(item: $openStamp, onDismiss: openPendingDay) { tally in
            ReviewStampSheet(
                tally: tally,
                periodTitle: periodTitle,
                days: model.stampDays(of: tally),
                entryDay: model.day(on:)
            ) { date in
                pendingDay = date
                openStamp = nil
            }
        }
        .errorBanner(model.errorNotice) {
            model.errorNotice.clear()
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
                .font(.serif(.body))
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
                    .font(.serif(.body))
                    .foregroundStyle(Palette.champagne)
                    .contentTransition(periodTextTransition)

                if let periodSubtitle {
                    Text(periodSubtitle)
                        .font(.sans(.caption))
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
            .animation(.snappy, value: model.kind)

            detailCard

            if model.kind != .balance {
                ReviewSharesCard(
                    title: "カテゴリごと",
                    shares: model.categoryShares,
                    total: ReviewSharesCard.Total(
                        title: totalTitle,
                        amount: model.total
                    ),
                    onOpen: { share in
                        openShare = share
                    }
                )

                ReviewSharesCard(
                    title: "口座ごと",
                    shares: model.walletShares,
                    total: nil,
                    onOpen: { share in
                        openShare = share
                    }
                )
            }

            if !model.stampTallies.isEmpty {
                stampCard
            }
        }
    }

    var stampCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle("押したスタンプ")

            LazyVGrid(columns: Self.stampColumns, alignment: .leading) {
                ForEach(model.stampTallies) { tally in
                    Button {
                        openStamp = tally
                    } label: {
                        HStack(spacing: 6) {
                            IconSeal(tally.icon, size: 28)

                            Text("×\(tally.count)")
                                .font(.serif(.body))
                                .monospacedDigit()
                                .foregroundStyle(Palette.champagne)
                        }
                        .contentShape(.rect)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .card()
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

            if let recurring = model.recurringTotal {
                Button {
                    openShare = model.recurringShare
                } label: {
                    HStack(spacing: 4) {
                        Label(recurringText(recurring), systemImage: "repeat")

                        Image(systemName: "chevron.right")
                            .font(.sans(.micro, weight: .semibold))
                    }
                    .font(.caption)
                    .monospacedDigit()
                    .foregroundStyle(Palette.mist)
                    .frame(minHeight: 28)
                    .contentShape(.rect)
                }
                .buttonStyle(.plain)
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
                    .font(.serif(.body))
                    .monospacedDigit()
                    .foregroundStyle(Palette.ink)
            }

            RatioBar(balanceRatio(of: amount), tint: tint, height: 6)
        }
    }

    func kindTile(_ kind: ReviewKind) -> some View {
        let isSelected = kind == model.kind
        let fill = isSelected ? Palette.gold.opacity(.subtle) : Color.clear
        let rim = isSelected ? Palette.gold : Palette.gold.opacity(.soft)
        let titleColor = isSelected ? Palette.gold : Palette.mist
        let amountColor = isSelected ? Palette.champagne : Palette.ink
        let change = model.change(of: kind)

        return Button {
            model.setKind(kind)

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
                    .font(.serif(.body))
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
}

private extension ReviewView {
    static let stampColumns = [
        GridItem(.adaptive(minimum: 72), spacing: 12, alignment: .leading)
    ]

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

                Task {
                    await model.saveSelection()
                }
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

    func recurringText(_ recurring: Int) -> String {
        let other = model.total(of: model.kind) - recurring
        let fixed = "固定費 \(AmountText.text(recurring))"
        return "\(fixed)・それ以外 \(AmountText.text(other))"
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

    func balanceRatio(of amount: Int) -> Double {
        let income = model.summary.income.total
        let expense = model.summary.expense.total
        let largest = max(income, expense)
        return largest > 0 ? Double(amount) / Double(largest) : 0
    }

    func choose(
        _ id: Entry.ID,
        in share: ReviewModel.Share
    ) {
        let isRecurring = share.id == ReviewModel.recurringShareId

        if isRecurring, let recurringId = model.recurringId(of: id) {
            pendingRecurring = recurringId
        } else {
            pendingEntry = id
        }

        openShare = nil
    }

    func openPendingDay() {
        guard let pendingDay else {
            return
        }

        self.pendingDay = nil
        onOpenDay(pendingDay)
    }

    func openPendingEntry() {
        if let pendingRecurring {
            self.pendingRecurring = nil
            onOpenRecurring(pendingRecurring)
            return
        }

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
