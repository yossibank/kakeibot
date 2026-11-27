import Core
import DesignSystem
import FeatureModels
import SwiftUI

public struct ReviewView: View {
    @Environment(\.themeStyle.corner) var corner
    @Environment(\.openURL) var openURL

    @Bindable private(set) var model: ReviewModel

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
        PageSlideReader { slide in
            screen(slide)
        }
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
            model.choose(id, in: share)
        }
    }

    @ViewBuilder
    func sheetView(
        _ sheet: ReviewModel.Sheet,
        slide: PageSlideProxy
    ) -> some View {
        switch sheet {
        case let .share(share):
            shareSheet(share)

        case .analysis:
            analysisSheet(slide)

        case let .stamp(tally):
            StampDaysSheet(
                tally: tally,
                periodTitle: periodTitle,
                days: model.output.stampDays(of: tally),
                entryDay: model.output.day(on:)
            ) { date in
                model.state.open(afterSheet: .day(date))
            }
        }
    }

    static func count(of direction: PageSwipeDirection) -> Int {
        direction == .forward ? 1 : -1
    }

    func openPending() {
        switch model.state.takePending() {
        case let .entry(id): onOpenEntry(id)
        case let .recurring(id): onOpenRecurring(id)
        case let .day(date): onOpenDay(date)
        case nil: break
        }
    }

    func move(
        _ direction: PageSwipeDirection,
        with slide: PageSlideProxy
    ) {
        move(by: Self.count(of: direction), with: slide)
    }

    func canMove(_ direction: PageSwipeDirection) -> Bool {
        model.output.canMove(by: Self.count(of: direction))
    }

    func move(
        by count: Int,
        with slide: PageSlideProxy
    ) {
        guard model.output.canMove(by: count) else {
            return
        }

        slide.run(forward: count > 0) {
            model.move(by: count)
        }
    }

    func moveToCurrentPeriod(with slide: PageSlideProxy) {
        slide.run(forward: true) {
            model.moveToCurrent()
        }
    }
}

private extension ReviewView {
    func screen(_ slide: PageSlideProxy) -> some View {
        ScrollView {
            VStack(spacing: 12) {
                header(slide)

                periodBar(slide)

                analysisBanner

                content
                    .pageSlide(slide, page: model.output.period)
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .onPageSwipe(following: slide, canMove: canMove) { direction in
            move(direction, with: slide)
        }
        .haptic(.selection, trigger: model.output.period)
        .haptic(.selection, trigger: model.input.kind)
        .task(id: model.output.goalTrigger) {
            await model.refreshGoals()
        }
        .task(id: model.input.list.value?.entries.count) {
            await model.refreshStoreReviewCard()
        }
        .sheet(item: Bindable(model.state).sheet, onDismiss: openPending) { sheet in
            sheetView(sheet, slide: slide)
        }
        .errorBanner(model.state.errorNotice)
        .backdrop()
    }

    func header(_ slide: PageSlideProxy) -> some View {
        TabHeader("振り返り") {
            CapsulePicker(selection: scaleBinding(slide), options: Self.scaleOptions)
        }
    }

    func periodBar(_ slide: PageSlideProxy) -> some View {
        PeriodStepper(
            title: periodTitle,
            subtitle: periodSubtitle,
            currentTitle: model.output.isCurrentPeriod ? nil : currentPeriodTitle,
            transition: periodTextTransition,
            canMoveForward: model.output.canMoveForward,
            onMove: { count in
                move(by: count, with: slide)
            },
            onCurrent: {
                moveToCurrentPeriod(with: slide)
            }
        )
    }
}

private extension ReviewView {
    static let scaleOptions: [CapsulePicker<ReviewPeriod.Scale>.Option] = [
        .init("週", value: .week),
        .init("月", value: .month),
        .init("年", value: .year)
    ]

    var periodSubtitle: String? {
        switch model.input.scale {
        case .week: nil
        case .month, .year: PeriodText.range(model.output.period.range)
        }
    }

    func scaleBinding(_ slide: PageSlideProxy) -> Binding<ReviewPeriod.Scale> {
        Binding {
            model.input.scale
        } set: { scale in
            let scales = ReviewPeriod.Scale.allCases
            let from = scales.firstIndex(of: model.input.scale) ?? 0
            let to = scales.firstIndex(of: scale) ?? 0

            slide.run(forward: to > from) {
                model.setScale(scale)

                model.perform {
                    await $0.saveSelection()
                }
            }
        }
    }
}
