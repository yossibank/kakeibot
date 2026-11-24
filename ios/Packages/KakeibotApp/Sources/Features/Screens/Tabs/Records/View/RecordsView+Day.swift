import Core
import DesignSystem
import FeatureModels
import SwiftUI

extension RecordsView {
    struct StampTarget: Identifiable {
        let date: LocalDate

        var id: LocalDate {
            date
        }
    }

    struct MarkMenu {
        let date: LocalDate
        let anchor: CGRect
    }

    func dayCard(_ day: EntryDay) -> some View {
        let rows = model.output.rows(for: day)

        return VStack(spacing: 0) {
            dayHeader(day.date, day: day)

            ForEach(rows) { row in
                recordRow(row)

                itemList(row)
            }

            adjustmentList(on: day.date)

            if selection == nil {
                let upcoming = model.output.listRecurrings(on: day.date)

                if !upcoming.isEmpty {
                    upcomingList(upcoming, on: day.date)
                        .padding(.top, 8)
                        .topHairline()
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 4)
        .card()
        .sharesTextScale(id: rows)
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
        let amount = model.output.amount(of: recurring, on: date)

        return HStack(spacing: 12) {
            Image(systemName: "repeat")
                .sansFont(.small, weight: .light)
                .foregroundStyle(Palette.hint)

            Text(model.output.title(of: recurring))
                .textFont(.subheadline)
                .foregroundStyle(Palette.subtext)
                .lineLimit(2)

            Spacer()

            AmountText(amount, type: recurring.type, font: .style(.subheadline))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .layoutPriority(1)
                .opacity(0.6)

            DisclosureMark()
        }
        .padding(.vertical, 8)
        .contentShape(.rect)
    }

    func listCaption(_ title: String) -> some View {
        Text(title)
            .textFont(.caption2)
            .tracking(2)
            .foregroundStyle(Palette.accent)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.top, 4)
    }

    func upcomingCard(on date: LocalDate) -> some View {
        VStack(spacing: 0) {
            dayHeader(date, day: nil)

            upcomingList(model.output.listRecurrings(on: date), on: date)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 4)
        .card()
    }

    @ViewBuilder
    func recordRow(_ row: EntryRowItem) -> some View {
        if let selection {
            let isSelected = selection.contains(row.id)

            Button {
                toggleSelection(row.id)
            } label: {
                HStack(spacing: 12) {
                    SelectionMark(isSelected: isSelected)

                    entryRow(row)
                }
                .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .topHairline()
        } else {
            Button {
                onOpenEntry(row.id)
            } label: {
                entryRow(row)
            }
            .buttonStyle(.plain)
            .topHairline()
        }
    }

    @ViewBuilder
    func adjustmentList(on date: LocalDate) -> some View {
        if selection == nil {
            ForEach(model.output.adjustmentRows(on: date)) { row in
                Button {
                    openAdjustment = row
                } label: {
                    RecordsAdjustmentRow(row: row)
                }
                .buttonStyle(.plain)
                .topHairline()
            }
        }
    }

    func openMarkMenu(on date: LocalDate, anchor: CGRect) {
        withAnimation(.snappy(duration: 0.25)) {
            markMenu = MarkMenu(date: date, anchor: anchor)
        }
    }

    func closeMarkMenu() {
        withAnimation(.snappy(duration: 0.2)) {
            markMenu = nil
        }
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
}

private extension RecordsView {
    func toggleSelection(_ id: Entry.ID) {
        guard let selection else {
            return
        }

        self.selection = model.output.toggling(id, in: selection)
    }
}
