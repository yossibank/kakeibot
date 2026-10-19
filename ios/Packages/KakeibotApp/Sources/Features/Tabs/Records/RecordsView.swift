import Core
import DesignSystem
import SwiftUI

public struct RecordsView: View {
    @Bindable private var model: RecordsModel

    @State private var openId: Entry.ID?
    @State private var isMovingForward = true
    @State private var slide = PageSlide()
    @State private var stampTarget: StampTarget?
    @State private var stampCount = 0

    private let onOpenEntry: (Entry.ID) -> Void
    private let onDelete: (Entry.ID) -> Void
    private let onAddEntry: (LocalDate) -> Void

    public init(
        model: RecordsModel,
        onOpenEntry: @escaping (Entry.ID) -> Void,
        onDelete: @escaping (Entry.ID) -> Void,
        onAddEntry: @escaping (LocalDate) -> Void
    ) {
        self.model = model
        self.onOpenEntry = onOpenEntry
        self.onDelete = onDelete
        self.onAddEntry = onAddEntry
    }

    public var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                header
                    .monthSwipe(perform: moveMonth)

                CapsulePicker(
                    selection: layoutBinding,
                    options: Self.layoutOptions
                )
                .frame(maxWidth: .infinity, alignment: .leading)

                monthContent
                    .pageSlide(slide)
            }
            .padding(.horizontal, 14)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .sensoryFeedback(.selection, trigger: model.month)
        .sensoryFeedback(.selection, trigger: model.selectedDate)
        .errorBanner(model.errorNotice) {
            model.errorNotice.clear()
        }
        .sheet(item: $stampTarget) { target in
            stampSheet(on: target.date)
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
                .font(.serif(.body))
                .tracking(3)
                .foregroundStyle(Palette.accent)

            Spacer()

            monthButton(systemImage: "chevron.left", months: -1)

            VStack(spacing: 1) {
                Text("\(String(model.month.year))年 \(model.month.month)月")
                    .font(.serif(.body))
                    .foregroundStyle(Palette.accentLight)
                    .contentTransition(monthTextTransition)

                Text(model.periodText)
                    .font(.sans(.caption))
                    .monospacedDigit()
                    .foregroundStyle(Palette.subtext)
                    .contentTransition(monthTextTransition)
            }

            monthButton(systemImage: "chevron.right", months: 1)
        }
    }

    var monthContent: some View {
        VStack(spacing: 12) {
            summary
                .monthSwipe(perform: moveMonth)

            switch model.layout {
            case .list:
                if model.days.isEmpty {
                    Text("この月の記録はありません")
                        .font(.footnote)
                        .foregroundStyle(Palette.subtext)
                        .padding(.vertical, 40)
                }

                ForEach(model.days, id: \.date) { day in
                    dayCard(day)
                }
            case .calendar:
                calendar
                    .monthSwipe(perform: moveMonth)

                shownDayCard
            }
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
                        .font(.caption2)
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
            } else {
                Text("この日の記録はありません")
                    .font(.footnote)
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
            total("支出", amount: model.expenseTotal, color: Palette.accentLight)
            total("収入", amount: model.incomeTotal, color: Palette.accent)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .overlay {
            RoundedRectangle(cornerRadius: 18)
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
                .font(.caption)
                .foregroundStyle(Palette.subtext)

            Text(AmountText.text(amount))
                .font(.serif(.body))
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
                        .font(.serif(.body))
                        .foregroundStyle(dayColor(date, isShown: isShown))
                        .frame(width: 30, height: 30)
                        .background(fill, in: Circle())
                        .overlay(Circle().stroke(ring, lineWidth: 1))
                        .overlay(alignment: .topTrailing) {
                            if let stamp = model.stampIcon(on: date) {
                                IconSeal(stamp, size: 18)
                                    .offset(x: 9, y: -7)
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
                    .font(.sans(.micro))
                    .foregroundStyle(Palette.accent)
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
            .font(.sans(.micro))
            .lineLimit(1)
            .minimumScaleFactor(0.6)
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
                .font(.footnote)
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
                    .font(.serif(.headline))
                    .foregroundStyle(Palette.accentLight)

                Text("（\(date.weekday.shortName)）")
                    .font(.caption)
                    .foregroundStyle(Self.weekdayColor(for: date))

                if let holiday {
                    Text(holiday)
                        .font(.caption2)
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
        .font(.caption)
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
        .init("一覧", value: .list),
        .init("カレンダー", value: .calendar)
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
        if Holiday.contains(date) || date.weekday == .sunday {
            return Palette.holiday
        }

        return date.weekday.tint ?? Palette.subtext
    }

    func dayColor(
        _ date: LocalDate,
        isShown: Bool
    ) -> Color {
        if isShown {
            return Palette.backgroundBottom
        }

        if Holiday.contains(date) {
            return Palette.holiday
        }

        return date.weekday.tint ?? Palette.text
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
        perform action: @escaping (PageSwipeDirection) -> Void
    ) -> some View {
        contentShape(.rect)
            .onPageSwipe(perform: action)
    }
}
