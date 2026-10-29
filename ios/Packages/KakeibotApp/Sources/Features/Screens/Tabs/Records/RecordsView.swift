import Core
import DesignSystem
import SwiftUI

public struct RecordsView: View {
    @Bindable var model: RecordsModel

    @State var openId: Entry.ID?
    @State var stampTarget: StampTarget?
    @State var rewardTarget: StampTarget?
    @State var selection: Set<Entry.ID>?
    @State var batchTarget: RecordsBatchSheet.Target?
    @State var isFiltering = false

    @FocusState var isSearchFocused: Bool

    @State private var isMovingForward = true
    @State private var slide = PageSlide()
    @State private var stampCount = 0

    let onOpenEntry: (Entry.ID) -> Void
    let onDelete: (Entry.ID) -> Void
    let onAddEntry: (LocalDate) -> Void
    let onOpenRecurring: (Recurring.ID) -> Void
    let onDeleteEntries: ([Entry.ID]) -> Void

    private let onChangeEntries: ([Entry.ID], EntryBatchChange) -> Void

    public init(
        model: RecordsModel,
        onOpenEntry: @escaping (Entry.ID) -> Void,
        onDelete: @escaping (Entry.ID) -> Void,
        onAddEntry: @escaping (LocalDate) -> Void,
        onOpenRecurring: @escaping (Recurring.ID) -> Void,
        onChangeEntries: @escaping ([Entry.ID], EntryBatchChange) -> Void,
        onDeleteEntries: @escaping ([Entry.ID]) -> Void
    ) {
        self.model = model
        self.onOpenEntry = onOpenEntry
        self.onDelete = onDelete
        self.onAddEntry = onAddEntry
        self.onOpenRecurring = onOpenRecurring
        self.onChangeEntries = onChangeEntries
        self.onDeleteEntries = onDeleteEntries
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
                        .monthSwipe(following: $slide, perform: moveMonth)

                    HStack(spacing: 8) {
                        CapsulePicker(
                            selection: layoutBinding,
                            options: Self.layoutOptions
                        )

                        Spacer()

                        if model.layout == .list {
                            selectButton
                        }

                        filterButton(title: "絞り込み")

                        toolButton(systemImage: "magnifyingglass", title: "検索") {
                            openSearch()
                        }
                    }

                    filterLine

                    Group {
                        monthContent
                    }
                    .pageSlide(slide)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .scrollDismissesKeyboard(.interactively)
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
            message: "削除した後も、知らせの『取り消す』で戻せます",
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
        .sensoryFeedback(.selection, trigger: model.month)
        .sensoryFeedback(.selection, trigger: model.selectedDate)
        .errorBanner(model.errorNotice) {
            model.errorNotice.clear()
        }
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
            RecordsFilterSheet(filter: $model.filter, list: model.list)
        }
        .sensoryFeedback(.success, trigger: stampCount)
        .background {
            Rectangle()
                .fill(Palette.background)
                .ignoresSafeArea()
        }
    }
}

private extension RecordsView {
    var header: some View {
        HStack {
            Text("記録")
                .displayFont(.body)
                .tracking(3)
                .foregroundStyle(Palette.accent)

            Spacer()

            monthButton(systemImage: "chevron.left", months: -1)

            VStack(spacing: 1) {
                Text("\(String(model.month.year))年 \(model.month.month)月")
                    .displayFont(.body)
                    .foregroundStyle(Palette.accentStrong)
                    .contentTransition(monthTextTransition)

                Text(model.periodText)
                    .textFont(size: .caption)
                    .monospacedDigit()
                    .foregroundStyle(Palette.subtext)
                    .contentTransition(monthTextTransition)
            }

            monthButton(systemImage: "chevron.right", months: 1)
        }
    }

    @ViewBuilder
    var filterLine: some View {
        if let title = model.filterTitle {
            RecordsFilterLine(title: title) {
                isFiltering = true
            } onClear: {
                withAnimation(.snappy) {
                    model.filter = EntryFilter()
                }
            }
        }
    }

    @ViewBuilder
    var monthContent: some View {
        summary
            .monthSwipe(following: $slide, perform: moveMonth)

        switch model.layout {
        case .list:
            if model.days.isEmpty {
                VStack(spacing: 16) {
                    Text("この月の記録はありません")
                        .textFont(.footnote)
                        .foregroundStyle(Palette.subtext)

                    if model.isCurrentMonth,
                       model.filter.isEmpty {
                        PrimaryButton("記録する") {
                            onAddEntry(model.today)
                        }
                    }
                }
                .padding(.vertical, 40)
            }

            ForEach(model.days, id: \.date) { day in
                dayCard(day)
            }
        case .calendar:
            calendar
                .monthSwipe(following: $slide, perform: moveMonth)

            shownDayCard
        }
    }

    func monthButton(
        systemImage: String,
        months: Int
    ) -> some View {
        Button {
            move(months: months)
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

private extension RecordsView {
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

    var monthTextTransition: ContentTransition {
        .numericText(countsDown: !isMovingForward)
    }

    func openSearch() {
        openId = nil

        withAnimation(.snappy) {
            model.isSearching = true
        }

        isSearchFocused = true
    }

    func moveMonth(_ direction: PageSwipeDirection) {
        switch direction {
        case .forward: move(months: 1)
        case .backward: move(months: -1)
        }
    }

    func move(months: Int) {
        openId = nil
        isMovingForward = months > 0

        PageSlide.run($slide, forward: months > 0) {
            model.move(months: months)
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
