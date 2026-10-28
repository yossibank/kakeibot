import Core
import DesignSystem
import Store
import SwiftUI

public struct ReviewView: View {
    @Environment(\.themeStyle.corner) private var corner

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
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .onPageSwipe(following: $slide, canMove: canMove) { direction in
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
                .fill(Palette.background)
                .ignoresSafeArea()
        }
    }
}

private extension ReviewView {
    var header: some View {
        HStack {
            Text("振り返り")
                .displayFont(.body)
                .tracking(3)
                .foregroundStyle(Palette.accent)

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
                    .displayFont(.body)
                    .foregroundStyle(Palette.accentStrong)
                    .contentTransition(periodTextTransition)

                if let periodSubtitle {
                    Text(periodSubtitle)
                        .textFont(size: .caption)
                        .monospacedDigit()
                        .foregroundStyle(Palette.subtext)
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

            if model.kind == .balance {
                let moves = model.moves

                if !moves.isEmpty {
                    moveCard(moves)
                }
            }

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
                        HStack(spacing: 8) {
                            IconSeal(tally.icon, size: 28)

                            Text("×\(tally.count)")
                                .displayFont(.body)
                                .monospacedDigit()
                                .foregroundStyle(Palette.accentStrong)
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
            HStack(spacing: 8) {
                Image(systemName: Self.changeImage(model.change))
                    .sansFont(.caption)
                    .foregroundStyle(selectedChangeColor)

                Text(comparisonText)
                    .textFont(.footnote)
                    .foregroundStyle(Palette.text)
            }

            if model.recurringTotal != nil
                || (model.kind == .expense && !model.moves.isEmpty) {
                VStack(alignment: .leading, spacing: 0) {
                    if let recurring = model.recurringTotal {
                        Button {
                            openShare = model.recurringShare
                        } label: {
                            HStack(spacing: 4) {
                                Label(recurringText(recurring), systemImage: "repeat")

                                Image(systemName: "chevron.right")
                                    .sansFont(.micro, weight: .semibold)
                            }
                            .textFont(.caption)
                            .monospacedDigit()
                            .foregroundStyle(Palette.subtext)
                            .frame(minHeight: 24)
                            .contentShape(.rect)
                        }
                        .buttonStyle(.plain)
                    }

                    if model.kind == .expense,
                       !model.moves.isEmpty {
                        Button {
                            select(.balance)
                        } label: {
                            HStack(spacing: 4) {
                                Label(moveText, systemImage: "arrow.right")

                                Image(systemName: "chevron.right")
                                    .sansFont(.micro, weight: .semibold)
                            }
                            .textFont(.caption)
                            .monospacedDigit()
                            .foregroundStyle(Palette.subtext)
                            .frame(minHeight: 24)
                            .contentShape(.rect)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            if model.kind == .balance {
                VStack(spacing: 12) {
                    balanceBar(
                        "収入",
                        amount: model.summary.income.total,
                        tint: Palette.accent
                    )

                    balanceBar(
                        "支出",
                        amount: model.summary.expense.total,
                        tint: Palette.accentStrong
                    )
                }
                .padding(.top, 8)
            }

            if let usage = model.budgetUsage {
                VStack(spacing: 8) {
                    HStack {
                        Text("予算 \(AmountText.text(usage.budget))")

                        Spacer()

                        Text(usage.remainingText)
                    }
                    .textFont(.caption)
                    .monospacedDigit()
                    .foregroundStyle(Palette.subtext)

                    UsageBar(usage)
                }
                .padding(.top, 4)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .card()
    }

    func moveCard(_ moves: [ReviewModel.Move]) -> some View {
        let total = ReviewModel.total(of: moves)
        let ratio = model.repaymentRatio(in: moves)
        let repaidPercent = Int((ratio * 100).rounded())

        return VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "arrow.left.arrow.right")
                    .sansFont(.small, weight: .semibold)
                    .foregroundStyle(Palette.accent)
                    .frame(width: 26, height: 26)
                    .background(Palette.accent.opacity(.subtle), in: Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text("返済と積立")
                        .textFont(.subheadline, weight: .semibold)
                        .foregroundStyle(Palette.text)

                    Text("支出には数えていません")
                        .textFont(.caption2)
                        .foregroundStyle(Palette.hint)
                }

                Spacer(minLength: 8)

                Text(AmountText.text(total))
                    .displayFont(.headline)
                    .monospacedDigit()
                    .foregroundStyle(Palette.accentStrong)
            }

            VStack(spacing: 8) {
                SplitBar(
                    ratio,
                    leading: Palette.accent,
                    trailing: Palette.accent.opacity(.medium)
                )

                HStack {
                    moveLegend(
                        "返済",
                        percent: repaidPercent,
                        color: Palette.accent
                    )

                    Spacer()

                    moveLegend(
                        "積立",
                        percent: 100 - repaidPercent,
                        color: Palette.accent.opacity(.medium)
                    )
                }
            }

            VStack(spacing: 0) {
                ForEach(moves) { move in
                    Button {
                        openShare = model.share(of: move)
                    } label: {
                        moveRow(move)
                    }
                    .buttonStyle(.plain)
                    .overlay(alignment: .top) {
                        Hairline(thickness: 1)
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .padding(.bottom, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .card()
        .sharesTextScale(id: moves.map(\.wallet.name))
    }

    func moveLegend(
        _ title: String,
        percent: Int,
        color: Color
    ) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)

            Text("\(title) \(percent)%")
                .textFont(.caption2)
                .monospacedDigit()
                .foregroundStyle(Palette.subtext)
        }
    }

    func moveRow(_ move: ReviewModel.Move) -> some View {
        HStack(spacing: 12) {
            IconBadge(move.icon, size: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(move.wallet.name)
                    .textFont(.subheadline)
                    .foregroundStyle(Palette.text)
                    .sharedTextScale()

                if let note = Self.moveNote(of: move) {
                    Text(note)
                        .textFont(.caption2)
                        .monospacedDigit()
                        .foregroundStyle(Palette.subtext)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
            }

            Spacer(minLength: 8)

            Text(AmountText.text(move.amount))
                .textFont(.subheadline)
                .monospacedDigit()
                .foregroundStyle(Palette.accentStrong)

            Image(systemName: "chevron.right")
                .sansFont(.small)
                .foregroundStyle(Palette.hint)
        }
        .padding(.vertical, 8)
        .contentShape(.rect)
    }

    func periodButton(
        systemImage: String,
        count: Int
    ) -> some View {
        Button {
            move(by: count)
        } label: {
            Image(systemName: systemImage)
                .sansFont(.small, weight: .semibold)
                .foregroundStyle(Palette.subtext)
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
        VStack(spacing: 4) {
            HStack {
                Text(title)
                    .textFont(.caption)
                    .foregroundStyle(Palette.subtext)

                Spacer()

                Text(AmountText.text(amount))
                    .displayFont(.body)
                    .monospacedDigit()
                    .foregroundStyle(Palette.text)
            }

            RatioBar(balanceRatio(of: amount), tint: tint, height: 6)
        }
    }

    func kindTile(_ kind: ReviewKind) -> some View {
        let isSelected = kind == model.kind
        let fill = isSelected ? Palette.accent.opacity(.subtle) : Color.clear
        let rim = isSelected ? Palette.accent : Palette.accent.opacity(.soft)
        let titleColor = isSelected ? Palette.accent : Palette.subtext
        let amountColor = isSelected ? Palette.accentStrong : Palette.text
        let change = model.change(of: kind)

        return Button {
            select(kind)
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Text(Self.title(of: kind))
                        .textFont(.caption)
                        .foregroundStyle(titleColor)

                    Spacer(minLength: 0)

                    Image(systemName: Self.changeImage(change))
                        .sansFont(.caption, weight: .semibold)
                        .foregroundStyle(Self.changeColor(change, of: kind))
                }

                Text(AmountText.text(model.total(of: kind)))
                    .displayFont(.body)
                    .monospacedDigit()
                    .foregroundStyle(amountColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
            .background(
                fill,
                in: RoundedRectangle(cornerRadius: corner.radius(16))
            )
            .overlay {
                RoundedRectangle(cornerRadius: corner.radius(16))
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
        case .week: return PeriodText.range(range, today: model.today)
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

    var moveText: String {
        let total = ReviewModel.total(of: model.moves)
        return "ほかに返済と積立 \(AmountText.text(total))"
    }

    var comparisonText: String {
        let previous = model.isComparingPartially
            ? Self.partialName(of: model.scale)
            : Self.previousName(of: model.scale)
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
            return Palette.subtext
        }

        let isGood = kind == .expense ? change < 0 : change > 0

        return isGood ? Palette.accent : Palette.rose
    }

    static func title(of kind: ReviewKind) -> String {
        switch kind {
        case .expense: "支出"
        case .income: "収入"
        case .balance: "収支"
        }
    }

    static func moveNote(of move: ReviewModel.Move) -> String? {
        guard move.wallet.archivedAt == nil else {
            return nil
        }

        let balance = AmountText.text(abs(move.balance))

        guard move.wallet.kind == .loan else {
            return "評価額 \(balance)"
        }

        guard move.balance < 0 else {
            return "返し終わりました"
        }

        guard let payoff = move.payoff else {
            return "残り \(balance)"
        }

        return "残り \(balance)・あと \(payoff.count) 回"
    }

    static func previousName(of scale: ReviewPeriod.Scale) -> String {
        switch scale {
        case .week: "前の週"
        case .month: "前の月"
        case .year: "前の年"
        }
    }

    static func partialName(of scale: ReviewPeriod.Scale) -> String {
        switch scale {
        case .week: "前の週の同じ曜日まで"
        case .month: "前の月の同じ日まで"
        case .year: "前の年の同じ日まで"
        }
    }

    static func count(of direction: PageSwipeDirection) -> Int {
        direction == .forward ? 1 : -1
    }

    func recurringText(_ recurring: Int) -> String {
        let other = model.total(of: model.kind) - recurring
        let fixed = "固定費 \(AmountText.text(recurring))"
        return "\(fixed)・それ以外 \(AmountText.text(other))"
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

    func select(_ kind: ReviewKind) {
        model.setKind(kind)

        Task {
            await model.saveSelection()
        }
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
        move(by: Self.count(of: direction))
    }

    func canMove(_ direction: PageSwipeDirection) -> Bool {
        model.canMove(by: Self.count(of: direction))
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
