import Core
import DesignSystem
import SwiftUI

extension RecordsView {
    struct StampTarget: Identifiable {
        let date: LocalDate

        var id: LocalDate {
            date
        }
    }

    func dayCard(_ day: EntryDay) -> some View {
        VStack(spacing: 0) {
            dayHeader(day.date, day: day)

            ForEach(model.rows(for: day)) { row in
                recordRow(row)

                itemList(row)
            }

            adjustmentList(on: day.date)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 4)
        .card()
        .sharesTextScale(id: model.rows(for: day))
    }

    @ViewBuilder
    func recordRow(_ row: EntryRowItem) -> some View {
        if let selection {
            let isSelected = selection.contains(row.id)
            let mark = isSelected ? "checkmark.circle.fill" : "circle"

            Button {
                toggleSelection(row.id)
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: mark)
                        .sansFont(.headline)
                        .foregroundStyle(Palette.accent)
                        .contentTransition(.symbolEffect(.replace))

                    entryRow(row)
                }
                .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .overlay(alignment: .top) {
                Hairline(thickness: 1)
            }
        } else {
            Button {
                onOpenEntry(row.id)
            } label: {
                entryRow(row)
            }
            .buttonStyle(.plain)
            .overlay(alignment: .top) {
                Hairline(thickness: 1)
            }
        }
    }

    @ViewBuilder
    func adjustmentList(on date: LocalDate) -> some View {
        if selection == nil {
            ForEach(model.adjustmentRows(on: date)) { row in
                Button {
                    openAdjustment = row
                } label: {
                    RecordsAdjustmentRow(row: row)
                }
                .buttonStyle(.plain)
                .overlay(alignment: .top) {
                    Hairline(thickness: 1)
                }
            }
        }
    }

    func dayHeader(
        _ date: LocalDate,
        day: EntryDay?
    ) -> some View {
        Group {
            if let selection,
               let day {
                ViewThatFits(in: .horizontal) {
                    dayHeaderRow(date, day: day) {
                        daySelectButton(day, in: selection, showsTitle: true)
                    }

                    dayHeaderRow(date, day: day) {
                        daySelectButton(day, in: selection, showsTitle: false)
                    }

                    dayHeaderStack(date, day: day) {
                        daySelectButton(day, in: selection, showsTitle: true)
                    }

                    dayHeaderStack(date, day: day) {
                        daySelectButton(day, in: selection, showsTitle: false)
                    }
                }
            } else {
                ViewThatFits(in: .horizontal) {
                    dayHeaderRow(date, day: day) {
                        dayButtons(on: date)
                    }

                    dayHeaderStack(date, day: day) {
                        dayButtons(on: date)
                    }
                }
            }
        }
        .padding(.top, 12)
        .padding(.bottom, 8)
    }
}

private extension RecordsView {
    func entryRow(_ row: EntryRowItem) -> some View {
        EntryRow(
            icon: row.icon,
            title: row.title,
            tag: row.tag,
            detail: row.detail,
            route: row.route,
            memo: row.memo,
            amount: row.amount,
            type: row.type,
            isRecurring: row.isRecurring
        )
    }

    func dayHeaderRow(
        _ date: LocalDate,
        day: EntryDay?,
        @ViewBuilder trailing: () -> some View
    ) -> some View {
        HStack(spacing: 12) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                dayTitle(date)

                if let holiday = Holiday.name(of: date) {
                    holidayText(holiday)
                }

                Spacer(minLength: 8)

                if let day {
                    dayTotals(day)
                        .fixedSize()
                }
            }

            trailing()
        }
    }

    func dayHeaderStack(
        _ date: LocalDate,
        day: EntryDay?,
        @ViewBuilder trailing: () -> some View
    ) -> some View {
        let holiday = Holiday.name(of: date)
        let hasTotals = day.map(Self.hasTotals) ?? false

        return VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 12) {
                dayTitle(date)

                Spacer(minLength: 8)

                trailing()
            }

            if holiday != nil || hasTotals {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    if let holiday {
                        holidayText(holiday)
                    }

                    Spacer(minLength: 8)

                    if let day {
                        dayTotals(day)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                            .layoutPriority(1)
                    }
                }
            }
        }
    }

    func dayTitle(_ date: LocalDate) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(PeriodText.day(date, today: model.today))
                .displayFont(.headline)
                .foregroundStyle(Palette.accentStrong)
                .fixedSize()

            Text("（\(date.weekday.shortName)）")
                .textFont(.caption)
                .foregroundStyle(Self.weekdayColor(for: date))
                .fixedSize()
        }
    }

    func holidayText(_ holiday: String) -> some View {
        Text(holiday)
            .textFont(.caption2)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .foregroundStyle(Palette.holiday)
    }

    @ViewBuilder
    func dayButtons(on date: LocalDate) -> some View {
        if model.canReward(on: date) {
            Button {
                rewardTarget = StampTarget(date: date)
            } label: {
                rewardButtonLabel(on: date)
                    .tapArea(Self.dayButtonTapOutsets)
            }
            .buttonStyle(.plain)
        }

        Button {
            stampTarget = StampTarget(date: date)
        } label: {
            stampButtonLabel(on: date)
                .tapArea(Self.dayButtonTapOutsets)
        }
        .buttonStyle(.plain)
    }

    func daySelectButton(
        _ day: EntryDay,
        in selection: Set<Entry.ID>,
        showsTitle: Bool
    ) -> some View {
        let isSelected = model.isSelected(day, in: selection)
        let mark = isSelected ? "checkmark.circle.fill" : "circle"

        return Button {
            self.selection = model.toggling(day, in: selection)
        } label: {
            HStack(spacing: 4) {
                if showsTitle {
                    Text("この日を選ぶ")
                        .textFont(.caption)
                        .foregroundStyle(Palette.accent)
                        .lineLimit(1)
                        .fixedSize()
                }

                Image(systemName: mark)
                    .sansFont(.headline)
                    .foregroundStyle(Palette.accent)
                    .contentTransition(.symbolEffect(.replace))
            }
            .frame(minHeight: 26)
            .tapArea(Self.dayButtonTapOutsets)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    func rewardButtonLabel(on date: LocalDate) -> some View {
        if model.rewardTotal(on: date) > 0 {
            Image(systemName: "gift.fill")
                .sansFont(.small)
                .foregroundStyle(Palette.background)
                .frame(width: 26, height: 26)
                .background(Palette.accent, in: .circle)
        } else {
            Image(systemName: "gift")
                .sansFont(.small)
                .foregroundStyle(Palette.subtext)
                .frame(width: 26, height: 26)
                .overlay {
                    Circle()
                        .stroke(Palette.subtext.opacity(.muted), style: .dashed)
                }
        }
    }

    @ViewBuilder
    func stampButtonLabel(on date: LocalDate) -> some View {
        if let stamp = model.stampIcon(on: date) {
            IconSeal(stamp, size: 26)
        } else {
            Image(systemName: "seal")
                .sansFont(.small)
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
    }
}

private extension RecordsView {
    static let dayButtonTapOutsets = EdgeInsets(
        top: 9,
        leading: 6,
        bottom: 9,
        trailing: 6
    )

    static func weekdayColor(for date: LocalDate) -> Color {
        date.tint ?? Palette.subtext
    }

    static func hasTotals(_ day: EntryDay) -> Bool {
        day.expenseTotal > 0 || day.incomeTotal > 0
    }

    func toggleSelection(_ id: Entry.ID) {
        guard let selection else {
            return
        }

        self.selection = model.toggling(id, in: selection)
    }
}
