import Core
import DesignSystem
import SwiftUI

public struct RecordsView: View {
    @Environment(\.themeStyle.corner) private var corner

    @Bindable private var model: RecordsModel

    @State private var openId: Entry.ID?
    @State private var isMovingForward = true
    @State private var slide = PageSlide()
    @State private var stampTarget: StampTarget?
    @State private var stampCount = 0
    @State private var isFiltering = false

    @FocusState private var isSearchFocused: Bool

    private let onOpenEntry: (Entry.ID) -> Void
    private let onDelete: (Entry.ID) -> Void
    private let onAddEntry: (LocalDate) -> Void
    private let onOpenRecurring: (Recurring.ID) -> Void

    public init(
        model: RecordsModel,
        onOpenEntry: @escaping (Entry.ID) -> Void,
        onDelete: @escaping (Entry.ID) -> Void,
        onAddEntry: @escaping (LocalDate) -> Void,
        onOpenRecurring: @escaping (Recurring.ID) -> Void
    ) {
        self.model = model
        self.onOpenEntry = onOpenEntry
        self.onDelete = onDelete
        self.onAddEntry = onAddEntry
        self.onOpenRecurring = onOpenRecurring
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

                        filterButton

                        toolButton(systemImage: "magnifyingglass") {
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
            .padding(.horizontal, 14)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .scrollDismissesKeyboard(.interactively)
        .sensoryFeedback(.selection, trigger: model.month)
        .sensoryFeedback(.selection, trigger: model.selectedDate)
        .errorBanner(model.errorNotice) {
            model.errorNotice.clear()
        }
        .sheet(item: $stampTarget) { target in
            stampSheet(on: target.date)
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

    var searchBar: some View {
        HStack(spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Palette.subtext)

                TextField(
                    "メモ・カテゴリ・口座・金額",
                    text: $model.searchText,
                    prompt: Text("メモ・カテゴリ・口座・金額")
                        .foregroundStyle(Palette.hint)
                )
                .textFont(.subheadline)
                .foregroundStyle(Palette.text)
                .tint(Palette.accent)
                .submitLabel(.search)
                .focused($isSearchFocused)
                .onSubmit {
                    rememberSearch()
                }

                if !model.searchText.isEmpty {
                    Button {
                        model.searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(Palette.hint)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 14)
            .frame(height: 44)
            .background(Palette.faint, in: Capsule())
            .overlay {
                Capsule()
                    .stroke(Palette.outline, lineWidth: 1)
            }

            filterButton

            Button("閉じる") {
                closeSearch()
            }
            .textFont(.subheadline)
            .foregroundStyle(Palette.accent)
        }
    }

    @ViewBuilder
    var searchContent: some View {
        let days = model.searchDays

        if EntrySearch(model.searchText).isEmpty {
            if model.recentSearches.isEmpty {
                Text("メモ・カテゴリ・タグ・口座の名前や、金額で探せます")
                    .textFont(.footnote)
                    .foregroundStyle(Palette.subtext)
                    .padding(.vertical, 40)
            } else {
                recentList
            }
        } else if let summary = model.searchSummary {
            searchSummary(summary)

            ForEach(days, id: \.self) { day in
                dayCard(day)
            }
        } else {
            Text("見つかりませんでした")
                .textFont(.footnote)
                .foregroundStyle(Palette.subtext)
                .padding(.vertical, 40)
        }
    }

    var recentList: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("最近探した言葉")
                    .textFont(.caption2)
                    .tracking(2)
                    .foregroundStyle(Palette.accent)

                Spacer()

                Button {
                    Task {
                        await model.clearRecentSearches()
                    }
                } label: {
                    Text("消す")
                        .textFont(.caption)
                        .foregroundStyle(Palette.subtext)
                        .padding(.horizontal, 8)
                        .frame(minHeight: 36)
                        .contentShape(.rect)
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 10)
            .padding(.bottom, 6)

            ForEach(model.recentSearches, id: \.self) { word in
                Button {
                    model.searchText = word
                    rememberSearch()
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.footnote)
                            .foregroundStyle(Palette.subtext)

                        Text(word)
                            .textFont(.subheadline)
                            .foregroundStyle(Palette.text)
                            .lineLimit(1)

                        Spacer()
                    }
                    .frame(minHeight: 44)
                    .contentShape(.rect)
                }
                .buttonStyle(.plain)
                .overlay(alignment: .top) {
                    Hairline(thickness: 1)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 4)
        .card()
    }

    func searchSummary(_ summary: RecordsModel.SearchSummary) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Text("\(summary.count) 件")
                    .textFont(.subheadline)
                    .monospacedDigit()
                    .foregroundStyle(Palette.accentStrong)

                Spacer()

                Text(PeriodText.range(summary.range))
                    .textFont(.caption)
                    .monospacedDigit()
                    .foregroundStyle(Palette.subtext)
            }

            HStack(spacing: 0) {
                total(
                    "支出",
                    amount: summary.expenseTotal,
                    color: Palette.accentStrong
                )

                total(
                    "収入",
                    amount: summary.incomeTotal,
                    color: Palette.accent
                )
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .overlay {
            RoundedRectangle(cornerRadius: corner.radius(18))
                .strokeBorder(Palette.accent.opacity(.soft), lineWidth: 1)
        }
    }

    var filterButton: some View {
        toolButton(
            systemImage: "line.3.horizontal.decrease",
            isOn: !model.filter.isEmpty
        ) {
            isFiltering = true
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

    func toolButton(
        systemImage: String,
        isOn: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        let fill = isOn ? Palette.accent.opacity(.subtle) : Color.clear
        let ring = isOn ? Palette.accent : Palette.line

        return Button(action: action) {
            Image(systemName: systemImage)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Palette.accent)
                .frame(width: 36, height: 36)
                .background(fill, in: Circle())
                .overlay {
                    Circle()
                        .stroke(ring, lineWidth: 1)
                }
                .frame(width: 44, height: 44)
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    var monthContent: some View {
        summary
            .monthSwipe(following: $slide, perform: moveMonth)

        switch model.layout {
        case .list:
            if model.days.isEmpty {
                Text("この月の記録はありません")
                    .textFont(.footnote)
                    .foregroundStyle(Palette.subtext)
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

    var calendar: some View {
        VStack(spacing: 2) {
            HStack(spacing: 0) {
                ForEach(
                    Weekday.week(startingOn: model.weekStart),
                    id: \.self
                ) { weekday in
                    Text(weekday.shortName)
                        .textFont(.caption2)
                        .foregroundStyle(weekday.tint ?? Palette.subtext)
                        .frame(maxWidth: .infinity, minHeight: 22)
                }
            }

            ForEach(
                Array(model.weeks.enumerated()),
                id: \.offset
            ) { _, week in
                HStack(spacing: 0) {
                    ForEach(
                        Array(week.enumerated()),
                        id: \.offset
                    ) { _, date in
                        calendarCell(date)
                    }
                }
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 10)
        .card()
    }

    var shownDayCard: some View {
        let date = model.shownDate
        let day = model.day(on: date)

        return VStack(spacing: 0) {
            dayHeader(date, day: day)

            if let day {
                ForEach(model.rows(for: day)) { row in
                    swipeRow(row)
                }
            }

            let upcoming = model.upcomingRecurrings(on: date)

            if !upcoming.isEmpty {
                upcomingList(upcoming, on: date)
            } else if day == nil {
                Text("この日の記録はありません")
                    .textFont(.footnote)
                    .foregroundStyle(Palette.subtext)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.bottom, 12)
            }

            HStack(spacing: 0) {
                dayButton("この日に入力", systemImage: "plus") {
                    onAddEntry(date)
                }

                if model.canMarkNoSpend(on: date) {
                    Rectangle()
                        .fill(Palette.hairline)
                        .frame(width: 1, height: 24)

                    noSpendButton(date)
                }
            }
            .overlay(alignment: .top) {
                Hairline(thickness: 1)
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 4)
        .card()
    }

    var summary: some View {
        HStack(spacing: 0) {
            total("支出", amount: model.expenseTotal, color: Palette.accentStrong)
            total("収入", amount: model.incomeTotal, color: Palette.accent)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .overlay {
            RoundedRectangle(cornerRadius: corner.radius(18))
                .strokeBorder(Palette.accent.opacity(.soft), lineWidth: 1)
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
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Palette.subtext)
                .frame(width: 40, height: 44)
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }

    func total(
        _ title: String,
        amount: Int,
        color: Color
    ) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            Text(title)
                .textFont(.caption)
                .foregroundStyle(Palette.subtext)

            Text(AmountText.text(amount))
                .displayFont(.body)
                .monospacedDigit()
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    func calendarCell(_ date: LocalDate?) -> some View {
        if let date {
            let isShown = date == model.shownDate
            let fill = isShown ? Palette.accent : Color.clear
            let ring = date == model.today && !isShown ? Palette.accent : .clear
            let opacity = date > model.today && !isShown ? 0.45 : 1

            Button {
                model.selectedDate = date
            } label: {
                VStack(spacing: 3) {
                    Text(String(date.day))
                        .displayFont(.body)
                        .foregroundStyle(dayColor(date, isShown: isShown))
                        .frame(width: 30, height: 30)
                        .background(fill, in: Circle())
                        .overlay(Circle().stroke(ring, lineWidth: 1))
                        .overlay(alignment: .topTrailing) {
                            if let stamp = model.stampIcon(on: date) {
                                IconSeal(stamp, size: 22)
                                    .offset(x: 11, y: -9)
                                    .id(stamp.id)
                                    .transition(Self.stampTransition)
                            }
                        }
                        .animation(
                            Self.stampAnimation,
                            value: model.stampIcon(on: date)?.id
                        )

                    dayMark(date)
                        .frame(height: 24, alignment: .top)
                }
                .opacity(opacity)
                .frame(maxWidth: .infinity, minHeight: 62)
                .contentShape(.rect)
            }
            .buttonStyle(.plain)
        } else {
            Color.clear
                .frame(maxWidth: .infinity, minHeight: 62)
        }
    }

    func dayMark(_ date: LocalDate) -> some View {
        let day = model.day(on: date)
        let expense = day?.expenseTotal ?? 0
        let income = day?.incomeTotal ?? 0

        return VStack(spacing: 0) {
            if expense > 0 {
                markAmount(expense, type: .expense)
            } else if model.noSpendDays.contains(date) {
                Image(systemName: "leaf.fill")
                    .sansFont(.micro)
                    .foregroundStyle(Palette.accent)
            } else if !model.upcomingRecurrings(on: date).isEmpty {
                Image(systemName: "repeat")
                    .sansFont(.micro)
                    .foregroundStyle(Palette.hint)
            }

            if income > 0 {
                markAmount(income, type: .income)
            }
        }
    }

    func markAmount(
        _ amount: Int,
        type: Entry.Kind
    ) -> some View {
        AmountText(amount, type: type)
            .textFont(size: .micro)
            .lineLimit(1)
            .minimumScaleFactor(0.6)
    }

    func upcomingList(
        _ recurrings: [Recurring],
        on date: LocalDate
    ) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("予定の固定費")
                .textFont(.caption2)
                .tracking(2)
                .foregroundStyle(Palette.hint)
                .padding(.bottom, 4)

            ForEach(recurrings, id: \.id) { recurring in
                Button {
                    onOpenRecurring(recurring.id)
                } label: {
                    upcomingRow(recurring, on: date)
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.bottom, 8)
    }

    func upcomingRow(
        _ recurring: Recurring,
        on date: LocalDate
    ) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "repeat")
                .sansFont(.small, weight: .light)
                .foregroundStyle(Palette.hint)

            Text(model.title(of: recurring))
                .textFont(.subheadline)
                .foregroundStyle(Palette.subtext)
                .lineLimit(2)

            Spacer()

            AmountText(
                model.amount(of: recurring, on: date),
                type: recurring.type
            )
            .textFont(.subheadline)
            .opacity(0.6)

            Image(systemName: "chevron.right")
                .font(.footnote)
                .foregroundStyle(Palette.hint)
        }
        .padding(.vertical, 8)
        .contentShape(.rect)
    }

    func noSpendButton(_ date: LocalDate) -> some View {
        let isMarked = model.noSpendDays.contains(date)
        let title = isMarked ? "支出なしの印を外す" : "支出なしの日にする"
        let image = isMarked ? "leaf.fill" : "leaf"

        return dayButton(title, systemImage: image) {
            Task {
                await model.toggleNoSpendDay(on: date)
            }
        }
    }

    func dayButton(
        _ title: String,
        systemImage: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .textFont(.footnote)
                .foregroundStyle(Palette.accent)
                .frame(maxWidth: .infinity, minHeight: 44)
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }

    func dayCard(_ day: EntryDay) -> some View {
        VStack(spacing: 0) {
            dayHeader(day.date, day: day)

            ForEach(model.rows(for: day)) { row in
                swipeRow(row)
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 4)
        .card()
    }

    func swipeRow(_ row: EntryRowItem) -> some View {
        SwipeRow(id: row.id, openId: $openId) {
            onOpenEntry(row.id)
        } onAction: {
            onDelete(row.id)
        } content: {
            EntryRow(
                icon: row.icon,
                title: row.title,
                tag: row.tag,
                detail: row.detail,
                memo: row.memo,
                amount: row.amount,
                type: row.type,
                isRecurring: row.isRecurring
            )
        }
        .overlay(alignment: .top) {
            Hairline(thickness: 1)
        }
    }

    func stampSheet(on date: LocalDate) -> some View {
        RecordsStampSheet(
            date: date,
            choices: model.stampChoices,
            current: model.stampIcon(on: date)
        ) { icon in
            stampCount += 1

            Task {
                await model.stamp(icon, on: date)
            }
        } onRemove: {
            Task {
                await model.removeStamp(on: date)
            }
        }
    }

    func dayHeader(
        _ date: LocalDate,
        day: EntryDay?
    ) -> some View {
        let holiday = Holiday.name(of: date)

        return HStack(spacing: 10) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text("\(date.month)/\(date.day)")
                    .displayFont(.headline)
                    .foregroundStyle(Palette.accentStrong)

                Text("（\(date.weekday.shortName)）")
                    .textFont(.caption)
                    .foregroundStyle(Self.weekdayColor(for: date))

                if let holiday {
                    Text(holiday)
                        .textFont(.caption2)
                        .foregroundStyle(Palette.holiday)
                }

                Spacer(minLength: 8)

                if let day {
                    dayTotals(day)
                }
            }

            Button {
                stampTarget = StampTarget(date: date)
            } label: {
                stampButtonLabel(on: date)
            }
            .buttonStyle(.plain)
        }
        .padding(.top, 12)
        .padding(.bottom, 8)
    }

    @ViewBuilder
    func stampButtonLabel(on date: LocalDate) -> some View {
        if let stamp = model.stampIcon(on: date) {
            IconSeal(stamp, size: 26)
        } else {
            Image(systemName: "seal")
                .font(.footnote)
                .foregroundStyle(Palette.subtext)
                .frame(width: 26, height: 26)
                .overlay {
                    Circle()
                        .stroke(Palette.subtext.opacity(.muted), style: .dashed)
                }
        }
    }

    func dayTotals(_ day: EntryDay) -> some View {
        HStack(spacing: 8) {
            if day.expenseTotal > 0 {
                AmountText(day.expenseTotal, type: .expense)
            }

            if day.incomeTotal > 0 {
                AmountText(day.incomeTotal, type: .income)
            }
        }
        .textFont(.caption)
        .lineLimit(1)
    }
}

private extension RecordsView {
    struct StampTarget: Identifiable {
        let date: LocalDate

        var id: LocalDate {
            date
        }
    }

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

    static var stampTransition: AnyTransition {
        .scale(scale: 0.2).combined(with: .opacity)
    }

    static var stampAnimation: Animation {
        .bouncy(duration: 0.45, extraBounce: 0.25)
    }

    static func weekdayColor(for date: LocalDate) -> Color {
        date.tint ?? Palette.subtext
    }

    func dayColor(
        _ date: LocalDate,
        isShown: Bool
    ) -> Color {
        if isShown {
            return Palette.backgroundBottom
        }

        return date.tint ?? Palette.text
    }

    func openSearch() {
        openId = nil

        withAnimation(.snappy) {
            model.isSearching = true
        }

        isSearchFocused = true
    }

    func rememberSearch() {
        let text = model.searchText

        Task {
            await model.rememberSearch(text)
        }
    }

    func closeSearch() {
        isSearchFocused = false
        openId = nil

        if model.searchSummary != nil {
            rememberSearch()
        }

        withAnimation(.snappy) {
            model.isSearching = false
            model.searchText = ""
        }
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
