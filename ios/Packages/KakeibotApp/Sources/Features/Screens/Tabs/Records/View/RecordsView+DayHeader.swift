import Core
import DesignSystem
import FeatureModels
import SwiftUI

extension RecordsView {
    func dayHeader(
        _ date: LocalDate,
        day: EntryDay?
    ) -> some View {
        Group {
            if let selection,
               let day {
                HStack(alignment: .firstTextBaseline, spacing: 12) {
                    daySelectButton(day, in: selection)

                    ViewThatFits(in: .horizontal) {
                        dayHeaderRow(date, day: day) {}

                        dayHeaderStack(date, day: day) {}
                    }
                }
            } else {
                ViewThatFits(in: .horizontal) {
                    dayHeaderRow(date, day: day) {
                        dayButtons(on: date)
                    }

                    dayHeaderRow(date, day: day, isCompact: true) {
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
    func dayHeaderRow(
        _ date: LocalDate,
        day: EntryDay?,
        isCompact: Bool = false,
        @ViewBuilder trailing: () -> some View
    ) -> some View {
        HStack(alignment: .dayTotals, spacing: 12) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                dayTitle(date)

                if let holiday = Holiday.name(of: date) {
                    holidayText(holiday)
                }

                Spacer(minLength: 8)

                if let day {
                    dayTotals(day, isCompact: isCompact)
                        .fixedSize()
                        .alignmentGuide(.dayTotals) { $0[VerticalAlignment.center] }
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
            Text(PeriodText.day(date, today: model.state.today))
                .displayFont(.headline)
                .foregroundStyle(Palette.accentStrong)
                .fixedSize()

            Text("（\(date.weekday.shortName)）")
                .textFont(.caption)
                .foregroundStyle(Self.weekdayColor(for: date))
                .fixedSize()

            if date == model.state.today {
                Text("今日")
                    .textFont(.caption2, weight: .semibold)
                    .foregroundStyle(Palette.accent)
                    .fixedSize()
                    .padding(.leading, -4)
            }
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
        let canReward = model.output.canReward(on: date)
        let hasReward = model.output.rewardTotal(on: date) > 0
        let hasStamp = model.output.stampIcon(on: date) != nil

        if canReward, !hasReward, !hasStamp {
            RecordsMarkButton { anchor in
                openMarkMenu(on: date, anchor: anchor)
            } label: {
                emptyButtonLabel("plus")
                    .tapArea(Self.dayButtonTapOutsets)
            }
        } else {
            if canReward {
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
    }

    func daySelectButton(
        _ day: EntryDay,
        in selection: Set<Entry.ID>
    ) -> some View {
        let isSelected = model.output.isSelected(day, in: selection)

        return Button {
            self.selection = model.output.toggling(day, in: selection)
        } label: {
            SelectionMark(isSelected: isSelected)
                .frame(minHeight: 26)
                .tapArea(Self.dayButtonTapOutsets)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    func rewardButtonLabel(on date: LocalDate) -> some View {
        if model.output.rewardTotal(on: date) > 0 {
            Image(systemName: "gift.fill")
                .sansFont(.small)
                .foregroundStyle(Palette.background)
                .frame(width: 26, height: 26)
                .background(Palette.accent, in: .circle)
        } else {
            emptyButtonLabel("gift")
        }
    }

    func emptyButtonLabel(_ systemImage: String) -> some View {
        Image(systemName: systemImage)
            .sansFont(.small)
            .foregroundStyle(Palette.subtext)
            .frame(width: 26, height: 26)
            .overlay {
                Circle()
                    .stroke(Palette.subtext.opacity(.muted), style: .dashed)
            }
    }

    @ViewBuilder
    func stampButtonLabel(on date: LocalDate) -> some View {
        if let stamp = model.output.stampIcon(on: date) {
            IconSeal(stamp, size: 26)
        } else {
            emptyButtonLabel("seal")
        }
    }

    func dayTotals(
        _ day: EntryDay,
        isCompact: Bool = false
    ) -> some View {
        HStack(spacing: 8) {
            if day.expenseTotal > 0 {
                AmountText(
                    day.expenseTotal,
                    type: .expense,
                    font: .style(.footnote),
                    isCompact: isCompact
                )
            }

            if day.incomeTotal > 0 {
                AmountText(
                    day.incomeTotal,
                    type: .income,
                    font: .style(.footnote),
                    isCompact: isCompact
                )
            }
        }
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
}

private extension VerticalAlignment {
    enum DayTotals: AlignmentID {
        static func defaultValue(in context: ViewDimensions) -> CGFloat {
            context[VerticalAlignment.center]
        }
    }

    static let dayTotals = VerticalAlignment(DayTotals.self)
}
