import Core
import DesignSystem
import FeatureModels
import SwiftUI

public struct RecordsView: View {
    @Bindable var model: RecordsModel

    @State var layout = Layout()

    @FocusState var isSearchFocused: Bool

    let onOpenEntry: (Entry.ID) -> Void
    let onAddEntry: (LocalDate) -> Void
    let onOpenRecurring: (Recurring.ID) -> Void
    let onDeleteEntries: ([Entry.ID]) -> Void
    let onChangeEntries: ([Entry.ID], EntryBatchChange) -> Void

    private let onDeleteAdjustment: (Deletion) -> Void

    public init(
        model: RecordsModel,
        onOpenEntry: @escaping (Entry.ID) -> Void,
        onAddEntry: @escaping (LocalDate) -> Void,
        onOpenRecurring: @escaping (Recurring.ID) -> Void,
        onChangeEntries: @escaping ([Entry.ID], EntryBatchChange) -> Void,
        onDeleteEntries: @escaping ([Entry.ID]) -> Void,
        onDeleteAdjustment: @escaping (Deletion) -> Void = { _ in }
    ) {
        self.model = model
        self.onOpenEntry = onOpenEntry
        self.onAddEntry = onAddEntry
        self.onOpenRecurring = onOpenRecurring
        self.onChangeEntries = onChangeEntries
        self.onDeleteEntries = onDeleteEntries
        self.onDeleteAdjustment = onDeleteAdjustment
    }

    public var body: some View {
        PageSlideReader { slide in
            screen(slide)
        }
    }
}

extension RecordsView {
    struct Layout {
        var markAnchor: CGRect = .zero
        var calendarWidth: CGFloat = 0
        var stampPulse: Double = 0
    }
}

private extension RecordsView {
    struct DayCardID: Hashable {
        let date: LocalDate
        let isSelecting: Bool
    }
}

extension RecordsView {
    var selection: Set<Entry.ID>? {
        model.state.screen.selection
    }

    var isCalendarWide: Bool {
        layout.calendarWidth >= Self.wideCalendarWidth
    }
}

private extension RecordsView {
    var header: some View {
        TabHeader("記録")
    }

    @ViewBuilder
    var filterLine: some View {
        if let title = model.output.filterTitle {
            RecordsFilterLine(title: title) {
                model.state.present(.filter)
            } onClear: {
                clearFilter()
            }
        }
    }

    @ViewBuilder
    var monthContent: some View {
        summary

        switch model.input.layout {
        case .list:
            if model.output.isMonthHiddenByFilter {
                filteredEmpty
            } else if model.output.showsNoRecords {
                PlaceholderEmpty(
                    systemImage: "calendar",
                    text: "この月の記録はありません",
                    onRecord: recordAction
                )
            }

            let days = model.output.listDays
            let captions = model.output.listCaptions(in: days)

            ForEach(days) { item in
                if selection == nil,
                   let caption = captions[item.date] {
                    listCaption(caption)
                }

                if let day = item.day {
                    dayCard(day)
                        .id(DayCardID(date: item.date, isSelecting: selection != nil))
                } else if selection == nil {
                    upcomingCard(on: item.date)
                }
            }

        case .calendar:
            TwoColumnStack(spacing: 12, minWidth: Self.wideCalendarWidth) {
                calendar

                shownDayCard
                    .layoutColumn(.trailing)
            }
            .onGeometryChange(for: CGFloat.self) { proxy in
                proxy.size.width
            } action: { width in
                layout.calendarWidth = width
            }
        }
    }

    @ViewBuilder
    var markMenuOverlay: some View {
        if let date = model.state.markMenuDate {
            RecordsMarkMenu(anchor: layout.markAnchor) {
                withAnimation(.snappy(duration: 0.2)) {
                    model.state.present(.stamp(date))
                }
            } onReward: {
                withAnimation(.snappy(duration: 0.2)) {
                    model.state.present(.reward(date))
                }
            } onClose: {
                closeMarkMenu()
            }
            .transition(.opacity)
        }
    }

    func scrollContent(_ slide: PageSlideProxy) -> some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                if model.state.isSearching {
                    searchBar

                    filterLine

                    searchContent
                } else {
                    monthPage(slide)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
    }

    @ViewBuilder
    func monthPage(_ slide: PageSlideProxy) -> some View {
        header

        monthStepper(slide)

        toolRow(slide)

        filterLine

        Group {
            monthContent
        }
        .frame(maxWidth: model.input.layout == .list ? Self.listWidth : nil)
        .pageSlide(slide, page: model.state.month)
    }

    func toolRow(_ slide: PageSlideProxy) -> some View {
        RecordsToolLayout(spacing: 8) {
            CapsulePicker(
                selection: layoutBinding(slide),
                options: Self.layoutOptions
            )

            HStack(spacing: 8) {
                if model.input.layout == .list {
                    selectButton
                }

                filterButton(title: "絞り込み")

                toolButton(systemImage: "magnifyingglass", title: "検索") {
                    openSearch()
                }
            }
        }
    }

    func screen(_ slide: PageSlideProxy) -> some View {
        scrollContent(slide)
            .contentShape(.rect)
            .onPageSwipe(following: slide, isEnabled: canSwipeMonth) { direction in
                moveMonth(direction, with: slide)
            }
            .scrollDismissesKeyboard(.interactively)
            .errorBanner(Bindable(model.state).errorNotice)
            .safeAreaInset(edge: .bottom) {
                if let selection {
                    selectionBar(selection)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .confirmation(
                isPresented: Bindable(model.state).isConfirmingDelete,
                systemImage: "trash",
                title: "\(model.output.pendingDeleteCount) 件の記録を削除しますか",
                message: deleteUndoMessage,
                keepTitle: "やめる",
                confirmTitle: "削除する"
            ) {
                model.state.confirmDelete { ids in
                    onDeleteEntries(ids)
                    finishSelecting()
                }
            }
            .onOutcome(model.state.outcome) { deletion in
                onDeleteAdjustment(deletion)
            }
            .onChange(of: model.input.layout) {
                finishSelecting()
            }
            .onChange(of: model.state.month) {
                finishSelecting()
            }
            .onChange(of: model.state.isSearching) {
                finishSelecting()
            }
            .haptic(.selection, trigger: model.state.month)
            .haptic(.selection, trigger: model.state.selectedDate)
            .sheet(item: Bindable(model.state).sheet) { sheet in
                sheetContent(sheet)
            }
            .overlay {
                markMenuOverlay
            }
            .onDisappear {
                model.state.closeMarkMenu()
            }
            .haptic(.success, trigger: layout.stampPulse)
            .backdrop()
    }

    func monthStepper(_ slide: PageSlideProxy) -> some View {
        PeriodStepper(
            title: model.state.month.title,
            subtitle: model.output.periodText,
            currentTitle: model.output.isCurrentMonth ? nil : "今月",
            transition: monthTextTransition,
            canMoveForward: true,
            onMove: { months in
                move(months: months, with: slide)
            },
            onCurrent: {
                moveToCurrentMonth(with: slide)
            }
        )
    }
}

private extension RecordsView {
    static let wideCalendarWidth: CGFloat = 560
    static let listWidth: CGFloat = 720

    static let layoutOptions: [CapsulePicker<RecordsLayout>.Option] = [
        .init("カレンダー", value: .calendar),
        .init("一覧", value: .list)
    ]

    var deleteUndoMessage: String {
        let seconds = EntryNoticeModel.Notice.batchSeconds
        return "削除してから \(seconds) 秒間は「取り消す」で戻せます"
    }

    var monthTextTransition: ContentTransition {
        .numericText(countsDown: !model.state.screen.isMovingForward)
    }

    var canSwipeMonth: Bool {
        !model.state.isSearching && selection == nil
    }

    var recordAction: (() -> Void)? {
        guard model.state.filter.isEmpty else {
            return nil
        }

        let date = model.output.isCurrentMonth ? model.state.today : model.output.period.lowerBound

        return {
            onAddEntry(date)
        }
    }

    func layoutBinding(_ slide: PageSlideProxy) -> Binding<RecordsLayout> {
        Binding {
            model.input.layout
        } set: { layout in
            let layouts = RecordsLayout.allCases
            let from = layouts.firstIndex(of: model.input.layout) ?? 0
            let to = layouts.firstIndex(of: layout) ?? 0

            slide.run(forward: to > from) {
                model.chooseLayout(layout)

                model.perform {
                    await $0.saveLayout()
                }
            }
        }
    }

    func openSearch() {
        withAnimation(.snappy) {
            model.state.isSearching = true
        }

        isSearchFocused = true
    }

    func moveMonth(
        _ direction: PageSwipeDirection,
        with slide: PageSlideProxy
    ) {
        guard canSwipeMonth else {
            return
        }

        switch direction {
        case .forward: move(months: 1, with: slide)
        case .backward: move(months: -1, with: slide)
        }
    }

    func move(
        months: Int,
        with slide: PageSlideProxy
    ) {
        model.state.head(forward: months > 0)

        slide.run(forward: months > 0) {
            model.state.move(months: months)
        }
    }

    func moveToCurrentMonth(with slide: PageSlideProxy) {
        let isForward = model.state.month < model.output.currentMonth

        model.state.head(forward: isForward)

        slide.run(forward: isForward) {
            model.openCurrentMonth()
        }
    }
}
