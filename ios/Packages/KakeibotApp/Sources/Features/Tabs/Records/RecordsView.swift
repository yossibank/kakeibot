import Core
import DesignSystem
import SwiftUI

public struct RecordsView: View {
    @Bindable private var model: RecordsModel

    @State private var openId: Entry.ID?
    @State private var isMovingForward = true
    @State private var slide = PageSlide()

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
        .background {
            Rectangle()
                .fill(Palette.night)
                .ignoresSafeArea()
        }
    }
}

private extension RecordsView {
    var header: some View {
        HStack {
            Text("記録")
                .font(.system(size: 15, design: .serif))
                .tracking(3)
                .foregroundStyle(Palette.gold)

            Spacer()

            monthButton(systemImage: "chevron.left", months: -1)

            VStack(spacing: 1) {
                Text("\(String(model.month.year))年 \(model.month.month)月")
                    .font(.system(size: 15, design: .serif))
                    .foregroundStyle(Palette.champagne)
                    .contentTransition(monthTextTransition)

                Text(model.periodText)
                    .font(.system(size: 10))
                    .monospacedDigit()
                    .foregroundStyle(Palette.mist)
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
                        .foregroundStyle(Palette.mist)
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
                        .foregroundStyle(weekday.tint ?? Palette.mist)
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
            dayHeader(date, total: day.flatMap(Self.totalText))

            if let day {
                ForEach(model.rows(for: day)) { row in
                    swipeRow(row)
                }
            } else {
                Text("この日の記録はありません")
                    .font(.footnote)
                    .foregroundStyle(Palette.mist)
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
            total("支出", amount: model.expenseTotal, color: Palette.champagne)
            total("収入", amount: model.incomeTotal, color: Palette.gold)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .overlay {
            RoundedRectangle(cornerRadius: 18)
                .strokeBorder(Palette.gold.opacity(0.2), lineWidth: 1)
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
                .foregroundStyle(Palette.mist)
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
                .foregroundStyle(Palette.mist)

            Text(AmountText.text(amount))
                .font(.system(size: 16, design: .serif))
                .monospacedDigit()
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    func calendarCell(_ date: LocalDate?) -> some View {
        if let date {
            let isShown = date == model.shownDate
            let fill = isShown ? Palette.gold : Color.clear
            let ring = date == model.today && !isShown ? Palette.gold : .clear
            let opacity = date > model.today && !isShown ? 0.45 : 1

            Button {
                model.selectedDate = date
            } label: {
                VStack(spacing: 3) {
                    Text(String(date.day))
                        .font(.system(size: 15, design: .serif))
                        .foregroundStyle(dayColor(date, isShown: isShown))
                        .frame(width: 30, height: 30)
                        .background(fill, in: Circle())
                        .overlay(Circle().stroke(ring, lineWidth: 1))

                    dayMark(date)
                        .frame(height: 12)
                }
                .opacity(opacity)
                .frame(maxWidth: .infinity, minHeight: 50)
                .contentShape(.rect)
            }
            .buttonStyle(.plain)
        } else {
            Color.clear
                .frame(maxWidth: .infinity, minHeight: 50)
        }
    }

    @ViewBuilder
    func dayMark(_ date: LocalDate) -> some View {
        let expense = model.day(on: date)?.expenseTotal ?? 0

        if expense > 0 {
            Text(AmountText.text(expense))
                .font(.system(size: 9))
                .monospacedDigit()
                .foregroundStyle(Palette.champagne)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        } else if model.noSpendDays.contains(date) {
            Image(systemName: "leaf.fill")
                .font(.system(size: 9))
                .foregroundStyle(Palette.gold)
        } else {
            Color.clear
        }
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
                .foregroundStyle(Palette.gold)
                .frame(maxWidth: .infinity, minHeight: 44)
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }

    func dayCard(_ day: EntryDay) -> some View {
        VStack(spacing: 0) {
            dayHeader(day.date, total: Self.totalText(for: day))

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

    func dayHeader(
        _ date: LocalDate,
        total: String?
    ) -> some View {
        let holiday = Holiday.name(of: date)

        return HStack(alignment: .firstTextBaseline, spacing: 6) {
            Text("\(date.month)/\(date.day)")
                .font(.system(size: 18, design: .serif))
                .foregroundStyle(Palette.champagne)

            Text("（\(date.weekday.shortName)）")
                .font(.caption)
                .foregroundStyle(Self.weekdayColor(for: date))

            if let holiday {
                Text(holiday)
                    .font(.caption2)
                    .foregroundStyle(Palette.holiday)
            }

            Spacer(minLength: 8)

            if let total {
                Text(total)
                    .font(.caption)
                    .foregroundStyle(Palette.mist)
                    .lineLimit(1)
            }
        }
        .padding(.top, 12)
        .padding(.bottom, 8)
    }
}

private extension RecordsView {
    static let layoutOptions: [CapsulePicker<RecordsLayout>.Option] = [
        .init("一覧", value: .list),
        .init("カレンダー", value: .calendar)
    ]

    var layoutBinding: Binding<RecordsLayout> {
        Binding {
            model.layout
        } set: { layout in
            Task {
                await model.setLayout(layout)
            }
        }
    }

    var monthTextTransition: ContentTransition {
        .numericText(countsDown: !isMovingForward)
    }

    static func weekdayColor(for date: LocalDate) -> Color {
        if Holiday.contains(date) || date.weekday == .sunday {
            return Palette.holiday
        }

        return date.weekday.tint ?? Palette.mist
    }

    static func totalText(for day: EntryDay) -> String? {
        let expense = day.expenseTotal > 0
            ? AmountText.text(day.expenseTotal)
            : nil

        let income = day.incomeTotal > 0
            ? "収入 \(AmountText.text(day.incomeTotal))"
            : nil

        let parts = [expense, income].compactMap(\.self)
        return parts.isEmpty ? nil : parts.joined(separator: "・")
    }

    func dayColor(
        _ date: LocalDate,
        isShown: Bool
    ) -> Color {
        if isShown {
            return Palette.nightBottom
        }

        if Holiday.contains(date) {
            return Palette.holiday
        }

        return date.weekday.tint ?? Palette.ink
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
