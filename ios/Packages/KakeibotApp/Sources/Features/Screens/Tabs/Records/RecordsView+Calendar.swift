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
                    swipeRow(row)
                }
            }

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
            let fill = isShown ? Palette.accent : Color.clear
            let ring = date == model.today && !isShown ? Palette.accent : .clear
            let opacity = date > model.today && !isShown ? 0.45 : 1

            Button {
                model.selectedDate = date
            } label: {
                VStack(spacing: 4) {
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
                        .animation(Self.stampAnimation, value: model.stampIcon(on: date)?.id)

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

            AmountText(amount, type: recurring.type)
                .textFont(.subheadline)
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
    static var stampTransition: AnyTransition {
        .scale(scale: 0.2).combined(with: .opacity)
    }

    static var stampAnimation: Animation {
        .bouncy(duration: 0.45, extraBounce: 0.25)
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
}
