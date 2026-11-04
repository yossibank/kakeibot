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

    func dayHeader(
        _ date: LocalDate,
        day: EntryDay?
    ) -> some View {
        let holiday = Holiday.name(of: date)

        return HStack(spacing: 12) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(PeriodText.day(date, today: model.today))
                    .displayFont(.headline)
                    .foregroundStyle(Palette.accentStrong)
                    .fixedSize()

                Text("（\(date.weekday.shortName)）")
                    .textFont(.caption)
                    .foregroundStyle(Self.weekdayColor(for: date))
                    .fixedSize()

                if let holiday {
                    Text(holiday)
                        .textFont(.caption2)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .foregroundStyle(Palette.holiday)
                }

                Spacer(minLength: 8)

                if let day {
                    dayTotals(day)
                }
            }

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
        .lineLimit(1)
        .minimumScaleFactor(0.8)
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

    func toggleSelection(_ id: Entry.ID) {
        guard var selected = selection else {
            return
        }

        if selected.contains(id) {
            selected.remove(id)
        } else {
            selected.insert(id)
        }

        selection = selected
    }
}
