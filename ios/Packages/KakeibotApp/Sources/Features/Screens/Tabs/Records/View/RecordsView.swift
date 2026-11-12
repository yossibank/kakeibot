import Core
import DesignSystem
import Store
import SwiftUI

public struct RecordsView: View {
    @Bindable var model: RecordsModel

    @State var stampTarget: StampTarget?
    @State var rewardTarget: StampTarget?
    @State var markMenu: MarkMenu?
    @State var selection: Set<Entry.ID>?
    @State var batchTarget: RecordsBatchSheet.Target?
    @State var isFiltering = false
    @State var openItemIds: Set<Entry.ID> = []
    @State var openAdjustment: RecordsModel.AdjustmentRow?
    @State var isCalendarWide = false

    @FocusState var isSearchFocused: Bool

    @State private var isMovingForward = true
    @State private var slide = PageSlide()
    @State private var stampCount = 0

    let onOpenEntry: (Entry.ID) -> Void
    let onAddEntry: (LocalDate) -> Void
    let onOpenRecurring: (Recurring.ID) -> Void
    let onDeleteEntries: ([Entry.ID]) -> Void

    private let onChangeEntries: ([Entry.ID], EntryBatchChange) -> Void
    private let onDeleteAdjustment: (Deletion) -> Void

    public init(
        model: RecordsModel,
        selection: Set<Entry.ID>? = nil,
        onOpenEntry: @escaping (Entry.ID) -> Void,
        onAddEntry: @escaping (LocalDate) -> Void,
        onOpenRecurring: @escaping (Recurring.ID) -> Void,
        onChangeEntries: @escaping ([Entry.ID], EntryBatchChange) -> Void,
        onDeleteEntries: @escaping ([Entry.ID]) -> Void,
        onDeleteAdjustment: @escaping (Deletion) -> Void = { _ in }
    ) {
        self.model = model
        _selection = State(initialValue: selection)
        self.onOpenEntry = onOpenEntry
        self.onAddEntry = onAddEntry
        self.onOpenRecurring = onOpenRecurring
        self.onChangeEntries = onChangeEntries
        self.onDeleteEntries = onDeleteEntries
        self.onDeleteAdjustment = onDeleteAdjustment
    }

    public var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                if model.isSearching {
                    searchBar

                    filterLine

                    searchContent
                } else {
                    header

                    monthStepper

                    RecordsToolLayout(spacing: 8) {
                        CapsulePicker(
                            selection: layoutBinding,
                            options: Self.layoutOptions
                        )

                        HStack(spacing: 8) {
                            if model.layout == .list {
                                selectButton
                            }

                            filterButton(title: "絞り込み")

                            toolButton(systemImage: "magnifyingglass", title: "検索") {
                                openSearch()
                            }
                        }
                    }

                    filterLine

                    Group {
                        monthContent
                    }
                    .pageSlide(slide, page: model.month)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .monthSwipe(following: swipeSlide, perform: moveMonth)
        .scrollDismissesKeyboard(.interactively)
        .errorBanner(model.errorNotice) {
            model.errorNotice.clear()
        }
        .safeAreaInset(edge: .bottom) {
            if let selection {
                selectionBar(selection)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .confirmation(
            isPresented: $model.isConfirmingDelete,
            systemImage: "trash",
            title: "\(model.pendingDeleteCount) 件の記録を削除しますか",
            message: deleteUndoMessage,
            keepTitle: "やめる",
            confirmTitle: "削除する"
        ) {
            model.confirmDelete { ids in
                onDeleteEntries(ids)
                finishSelecting()
            }
        }
        .onChange(of: model.layout) {
            finishSelecting()
        }
        .onChange(of: model.month) {
            finishSelecting()
        }
        .onChange(of: model.isSearching) {
            finishSelecting()
        }
        .haptic(.selection, trigger: model.month)
        .haptic(.selection, trigger: model.selectedDate)
        .sheet(item: $stampTarget) { target in
            RecordsStampSheet(
                date: target.date,
                choices: model.stampChoices,
                current: model.stampIcon(on: target.date),
                editModel: model.stampEditModel
            ) { icon in
                stampCount += 1

                Task {
                    await model.stamp(icon, on: target.date)
                }
            } onRemove: {
                Task {
                    await model.removeStamp(on: target.date)
                }
            }
        }
        .sheet(item: $rewardTarget) { target in
            RecordsRewardSheet(model: model, date: target.date)
        }
        .overlay {
            if let markMenu {
                RecordsMarkMenu(anchor: markMenu.anchor) {
                    closeMarkMenu()
                    stampTarget = StampTarget(date: markMenu.date)
                } onReward: {
                    closeMarkMenu()
                    rewardTarget = StampTarget(date: markMenu.date)
                } onClose: {
                    closeMarkMenu()
                }
                .transition(.opacity)
            }
        }
        .onDisappear {
            markMenu = nil
        }
        .sheet(item: $batchTarget) { target in
            RecordsBatchSheet(
                model: model,
                target: target,
                count: selection?.count ?? 0
            ) { change in
                onChangeEntries(Array(selection ?? []), change)
                finishSelecting()
            }
        }
        .sheet(isPresented: $isFiltering) {
            RecordsFilterSheet(model: model)
        }
        .sheet(item: $openAdjustment) { row in
            RecordsAdjustmentSheet(row: row) {
                deleteAdjustment(row.id)
            }
        }
        .haptic(.success, trigger: stampCount)
        .background {
            Backdrop()
                .ignoresSafeArea()
        }
    }
}

private extension RecordsView {
    var header: some View {
        TabHeader("記録")
    }

    var monthStepper: some View {
        PeriodStepper(
            title: "\(String(model.month.year))年 \(model.month.month)月",
            subtitle: model.periodText,
            currentTitle: model.isCurrentMonth ? nil : "今月",
            transition: monthTextTransition,
            canMoveForward: true,
            onMove: { months in
                move(months: months)
            },
            onCurrent: moveToCurrentMonth
        )
    }

    @ViewBuilder
    var filterLine: some View {
        if let title = model.filterTitle {
            RecordsFilterLine(title: title) {
                isFiltering = true
            } onClear: {
                clearFilter()
            }
        }
    }

    @ViewBuilder
    var monthContent: some View {
        summary

        switch model.layout {
        case .list:
            if model.isMonthHiddenByFilter {
                filteredEmpty
            } else if model.showsNoRecords {
                PlaceholderEmpty(
                    systemImage: "calendar",
                    text: "この月の記録はありません",
                    onRecord: recordAction
                )
            }

            ForEach(model.days, id: \.date) { day in
                dayCard(day)
            }

        case .calendar:
            TwoColumnStack(spacing: 12, minWidth: Self.wideCalendarWidth) {
                calendar

                shownDayCard
                    .layoutColumn(.trailing)
            }
            .onGeometryChange(for: Bool.self) { proxy in
                proxy.size.width >= Self.wideCalendarWidth
            } action: { isWide in
                isCalendarWide = isWide
            }
        }
    }
}

private extension RecordsView {
    static let wideCalendarWidth: CGFloat = 560

    static let layoutOptions: [CapsulePicker<RecordsLayout>.Option] = [
        .init("カレンダー", value: .calendar),
        .init("一覧", value: .list)
    ]

    var layoutBinding: Binding<RecordsLayout> {
        Binding {
            model.layout
        } set: { layout in
            let layouts = RecordsLayout.allCases
            let from = layouts.firstIndex(of: model.layout) ?? 0
            let to = layouts.firstIndex(of: layout) ?? 0

            PageSlide.run($slide, forward: to > from) {
                model.setLayout(layout)

                Task {
                    await model.saveLayout()
                }
            }
        }
    }

    var deleteUndoMessage: String {
        let seconds = EntryNoticeModel.Notice.batchSeconds
        return "削除してから \(seconds) 秒間は「取り消す」で戻せます"
    }

    var monthTextTransition: ContentTransition {
        .numericText(countsDown: !isMovingForward)
    }

    var canSwipeMonth: Bool {
        !model.isSearching && selection == nil
    }

    var swipeSlide: Binding<PageSlide> {
        canSwipeMonth ? $slide : .constant(PageSlide())
    }

    var recordAction: (() -> Void)? {
        guard model.filter.isEmpty else {
            return nil
        }

        let date = model.isCurrentMonth ? model.today : model.period.lowerBound

        return {
            onAddEntry(date)
        }
    }

    func openSearch() {
        withAnimation(.snappy) {
            model.isSearching = true
        }

        isSearchFocused = true
    }

    func moveMonth(_ direction: PageSwipeDirection) {
        guard canSwipeMonth else {
            return
        }

        switch direction {
        case .forward: move(months: 1)
        case .backward: move(months: -1)
        }
    }

    func move(months: Int) {
        isMovingForward = months > 0

        PageSlide.run($slide, forward: months > 0) {
            model.move(months: months)
        }
    }

    func moveToCurrentMonth() {
        let isForward = model.month < model.currentMonth

        isMovingForward = isForward

        PageSlide.run($slide, forward: isForward) {
            model.openCurrentMonth()
        }
    }

    func deleteAdjustment(_ id: Adjustment.ID) {
        Task {
            if let deletion = await model.deleteAdjustment(id) {
                onDeleteAdjustment(deletion)
            }
        }
    }
}

private extension View {
    func monthSwipe(
        following slide: Binding<PageSlide>,
        perform action: @escaping (PageSwipeDirection) -> Void
    ) -> some View {
        contentShape(.rect)
            .onPageSwipe(following: slide, perform: action)
    }
}
