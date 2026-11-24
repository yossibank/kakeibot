import Core
import DesignSystem
import Store
import SwiftUI

public struct ReviewView: View {
    @Environment(\.themeStyle.corner) var corner
    @Environment(\.openURL) var openURL

    @Bindable private(set) var model: ReviewModel

    @State var openShare: ReviewModel.Share?
    @State var openStamp: StampBook.Tally?
    @State var showsAnalysis = false
    @State var analysisShare: ReviewModel.Share?
    @State var slide = PageSlide()

    @State private var pendingEntry: Entry.ID?
    @State private var pendingRecurring: Recurring.ID?
    @State private var pendingDay: LocalDate?

    let onAddEntry: (LocalDate) -> Void
    let onOpenRecurrings: () -> Void

    private let onOpenEntry: (Entry.ID) -> Void
    private let onOpenRecurring: (Recurring.ID) -> Void
    private let onOpenDay: (LocalDate) -> Void

    public init(
        model: ReviewModel,
        onOpenEntry: @escaping (Entry.ID) -> Void,
        onOpenRecurring: @escaping (Recurring.ID) -> Void,
        onOpenDay: @escaping (LocalDate) -> Void,
        onAddEntry: @escaping (LocalDate) -> Void,
        onOpenRecurrings: @escaping () -> Void
    ) {
        self.model = model
        self.onOpenEntry = onOpenEntry
        self.onOpenRecurring = onOpenRecurring
        self.onOpenDay = onOpenDay
        self.onAddEntry = onAddEntry
        self.onOpenRecurrings = onOpenRecurrings
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                header

                periodBar

                analysisBanner

                content
                    .pageSlide(slide, page: model.output.period)
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .onPageSwipe(following: $slide, canMove: canMove) { direction in
            move(direction)
        }
        .haptic(.selection, trigger: model.output.period)
        .haptic(.selection, trigger: model.input.kind)
        .task(id: model.output.goalTrigger) {
            await model.refreshGoals()
        }
        .task(id: model.input.list?.entries.count) {
            await model.refreshStoreReviewCard()
        }
        .sheet(item: $openShare, onDismiss: openPendingEntry) { share in
            shareSheet(share)
        }
        .sheet(isPresented: $showsAnalysis, onDismiss: openPendingEntry) {
            analysisSheet
        }
        .sheet(item: $openStamp, onDismiss: openPendingDay) { tally in
            StampDaysSheet(
                tally: tally,
                periodTitle: periodTitle,
                days: model.output.stampDays(of: tally),
                entryDay: model.output.day(on:)
            ) { date in
                pendingDay = date
                openStamp = nil
            }
        }
        .errorBanner(model.state.errorNotice) {
            model.state.errorNotice.clear()
        }
        .backdrop()
    }
}

extension ReviewView {
    var periodTextTransition: ContentTransition {
        .numericText(countsDown: !model.state.isMovingForward)
    }

    var periodTitle: String {
        let range = model.output.period.range
        let month = range.upperBound.yearMonth

        switch model.input.scale {
        case .week: return PeriodText.range(range, today: model.state.today)
        case .month: return month.title
        case .year: return "\(String(month.year))年"
        }
    }

    var currentPeriodTitle: String {
        switch model.input.scale {
        case .week: "今週"
        case .month: "今月"
        case .year: "今年"
        }
    }

    func shareSheet(_ share: ReviewModel.Share) -> some View {
        ReviewShareSheet(
            share: share,
            periodTitle: periodTitle,
            rows: model.output.rows(for: share)
        ) { id in
            choose(id, in: share)
        }
    }

    static func count(of direction: PageSwipeDirection) -> Int {
        direction == .forward ? 1 : -1
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
        model.output.canMove(by: Self.count(of: direction))
    }

    func move(by count: Int) {
        guard model.output.canMove(by: count) else {
            return
        }

        PageSlide.run($slide, forward: count > 0) {
            model.move(by: count)
        }
    }

    func moveToCurrentPeriod() {
        PageSlide.run($slide, forward: true) {
            model.moveToCurrent()
        }
    }
}

private extension ReviewView {
    var header: some View {
        TabHeader("振り返り") {
            CapsulePicker(selection: scaleBinding, options: Self.scaleOptions)
        }
    }

    var periodBar: some View {
        PeriodStepper(
            title: periodTitle,
            subtitle: periodSubtitle,
            currentTitle: model.output.isCurrentPeriod ? nil : currentPeriodTitle,
            transition: periodTextTransition,
            canMoveForward: model.output.canMoveForward,
            onMove: { count in
                move(by: count)
            },
            onCurrent: moveToCurrentPeriod
        )
    }
}

private extension ReviewView {
    static let scaleOptions: [CapsulePicker<ReviewPeriod.Scale>.Option] = [
        .init("週", value: .week),
        .init("月", value: .month),
        .init("年", value: .year)
    ]

    var scaleBinding: Binding<ReviewPeriod.Scale> {
        Binding {
            model.input.scale
        } set: { scale in
            let scales = ReviewPeriod.Scale.allCases
            let from = scales.firstIndex(of: model.input.scale) ?? 0
            let to = scales.firstIndex(of: scale) ?? 0

            PageSlide.run($slide, forward: to > from) {
                model.setScale(scale)

                Task {
                    await model.saveSelection()
                }
            }
        }
    }

    var periodSubtitle: String? {
        switch model.input.scale {
        case .week: nil
        case .month, .year: PeriodText.range(model.output.period.range)
        }
    }

    func choose(
        _ id: Entry.ID,
        in share: ReviewModel.Share
    ) {
        let isRecurring = share.id == ReviewModel.recurringShareId

        if isRecurring,
           let recurringId = model.output.recurringId(of: id) {
            pendingRecurring = recurringId
        } else {
            pendingEntry = id
        }

        if analysisShare == nil {
            openShare = nil
        } else {
            analysisShare = nil
            showsAnalysis = false
        }
    }

    func openPendingDay() {
        guard let pendingDay else {
            return
        }

        self.pendingDay = nil

        onOpenDay(pendingDay)
    }
}
