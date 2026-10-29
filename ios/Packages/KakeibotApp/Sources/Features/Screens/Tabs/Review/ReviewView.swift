import Core
import DesignSystem
import Store
import SwiftUI

public struct ReviewView: View {
    @Environment(\.themeStyle.corner) var corner

    @Bindable private(set) var model: ReviewModel

    @State var openShare: ReviewModel.Share?
    @State var openStamp: StampCalendar.Tally?

    @State private var pendingEntry: Entry.ID?
    @State private var pendingRecurring: Recurring.ID?
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
}

private extension ReviewView {
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

    static func count(of direction: PageSwipeDirection) -> Int {
        direction == .forward ? 1 : -1
    }

    func choose(
        _ id: Entry.ID,
        in share: ReviewModel.Share
    ) {
        let isRecurring = share.id == ReviewModel.recurringShareId

        if isRecurring,
           let recurringId = model.recurringId(of: id) {
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
