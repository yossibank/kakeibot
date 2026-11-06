import Core
import DesignSystem
import SwiftUI

extension RecordsView {
    var calendar: some View {
        VStack(spacing: 2) {
            HStack(spacing: 0) {
                ForEach(Weekday.week(startingOn: model.weekStart), id: \.self) { weekday in
                    Text(weekday.shortName)
                        .textFont(.caption2)
                        .foregroundStyle(weekday.tint ?? Palette.subtext)
                        .frame(maxWidth: .infinity, minHeight: 22)
                }
            }

            ForEach(Array(model.weeks.enumerated()), id: \.offset) { _, week in
                HStack(spacing: 0) {
                    ForEach(Array(week.enumerated()), id: \.offset) { _, date in
                        calendarCell(date)
                    }
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 12)
        .card()
    }

    var shownDayCard: some View {
        let date = model.shownDate
        let day = model.day(on: date)

        return VStack(spacing: 0) {
            dayHeader(date, day: day)

            if let day {
                ForEach(model.rows(for: day)) { row in
                    recordRow(row)

                    itemList(row)
                }
            }

            adjustmentList(on: date)

            let upcoming = model.upcomingRecurrings(on: date)

            if !upcoming.isEmpty {
                upcomingList(upcoming, on: date)
            } else if day == nil,
                      model.list != nil {
                Text("この日の記録はありません")
                    .textFont(.footnote)
                    .foregroundStyle(Palette.subtext)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.bottom, 12)
            }

            HStack(spacing: 0) {
                dayButton("この日に記録する", systemImage: "plus") {
                    onAddEntry(date)
                }

                if model.canMarkNoSpend(on: date) {
                    let isMarked = model.noSpendDays.contains(date)
                    let title = isMarked ? "支出なしの印を外す" : "支出なしの日にする"
                    let image = isMarked ? "leaf.fill" : "leaf"

                    Rectangle()
                        .fill(Palette.hairline)
                        .frame(width: 1, height: 24)

                    dayButton(title, systemImage: image) {
                        Task {
                            await model.toggleNoSpendDay(on: date)
                        }
                    }
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
}

private extension RecordsView {
    @ViewBuilder
    func calendarCell(_ date: LocalDate?) -> some View {
        if let date {
            let isShown = date == model.shownDate
            let day = model.day(on: date)
            let expense = day?.expenseTotal ?? 0
            let isNoSpend = model.noSpendDays.contains(date)
            let hasUpcoming = expense == 0
                && !isNoSpend
                && !model.upcomingRecurrings(on: date).isEmpty

            RecordsCalendarCell(
                day: date.day,
                dayColor: dayColor(date, isShown: isShown),
                isShown: isShown,
                isToday: date == model.today,
                isDimmed: date > model.today && !isShown,
                stamp: model.stampIcon(on: date),
                expense: expense,
                income: day?.incomeTotal ?? 0,
                isNoSpend: isNoSpend,
                hasUpcoming: hasUpcoming
            ) {
                model.selectedDate = date
            }
            .equatable()
        } else {
            Color.clear
                .frame(maxWidth: .infinity, minHeight: 62)
        }
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
        let amount = model.amount(of: recurring, on: date)

        return HStack(spacing: 12) {
            Image(systemName: "repeat")
                .sansFont(.small, weight: .light)
                .foregroundStyle(Palette.hint)

            Text(model.title(of: recurring))
                .textFont(.subheadline)
                .foregroundStyle(Palette.subtext)
                .lineLimit(2)

            Spacer()

            AmountText(amount, type: recurring.type, font: .style(.subheadline))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .layoutPriority(1)
                .opacity(0.6)

            Image(systemName: "chevron.right")
                .sansFont(.small)
                .foregroundStyle(Palette.hint)
        }
        .padding(.vertical, 8)
        .contentShape(.rect)
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
}

private extension RecordsView {
    func dayColor(
        _ date: LocalDate,
        isShown: Bool
    ) -> Color {
        if isShown {
            return Palette.backgroundBottom
        }

        return date.tint ?? Palette.text
    }
}
