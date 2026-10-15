import Core
import DesignSystem
import SwiftUI

struct RecordsView: View {
    @Bindable var model: RecordsModel

    let onOpenEntry: (Entry.ID) -> Void

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                header
                summary

                if model.days.isEmpty {
                    Text("この月の記録はありません")
                        .font(.footnote)
                        .foregroundStyle(Palette.mist)
                        .padding(.vertical, 40)
                }

                ForEach(model.days, id: \.date) { day in
                    dayCard(day)
                }

                if let errorMessage = model.errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(Palette.rose)
                }
            }
            .padding(.horizontal, 14)
            .padding(.top, 8)
            .padding(.bottom, 24)
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

            Text("\(String(model.month.year))年 \(model.month.month)月")
                .font(.system(size: 15, design: .serif))
                .foregroundStyle(Palette.champagne)

            monthButton(systemImage: "chevron.right", months: 1)
        }
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
            withAnimation(.snappy) {
                model.move(months: months)
            }
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

    func dayCard(_ day: EntryDay) -> some View {
        VStack(spacing: 0) {
            dayHeader(day)

            ForEach(model.rows(for: day)) { row in
                Button {
                    onOpenEntry(row.id)
                } label: {
                    EntryRow(
                        icon: row.icon,
                        title: row.title,
                        tag: row.tag,
                        detail: row.detail,
                        amount: row.amount,
                        type: row.type
                    )
                }
                .buttonStyle(.plain)
                .overlay(alignment: .top) {
                    Rectangle()
                        .fill(Palette.gold.opacity(0.1))
                        .frame(height: 1)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 4)
        .card()
    }

    func dayHeader(_ day: EntryDay) -> some View {
        let holiday = Holiday.name(of: day.date)

        return HStack(alignment: .firstTextBaseline, spacing: 6) {
            Text("\(day.date.month)/\(day.date.day)")
                .font(.system(size: 18, design: .serif))
                .foregroundStyle(Palette.champagne)

            Text("（\(day.date.weekday.shortName)）")
                .font(.caption)
                .foregroundStyle(Self.weekdayColor(for: day.date))

            if let holiday {
                Text(holiday)
                    .font(.caption2)
                    .foregroundStyle(Palette.holiday)
            }

            Spacer(minLength: 8)

            Text(Self.totalText(for: day))
                .font(.caption)
                .foregroundStyle(Palette.mist)
                .lineLimit(1)
        }
        .padding(.top, 12)
        .padding(.bottom, 8)
    }
}

private extension RecordsView {
    static func weekdayColor(for date: LocalDate) -> Color {
        if Holiday.contains(date) || date.weekday == .sunday {
            return Palette.holiday
        }

        return date.weekday == .saturday ? Palette.saturday : Palette.mist
    }

    static func totalText(for day: EntryDay) -> String {
        let expense = AmountText.text(day.expenseTotal)

        guard day.incomeTotal > 0 else {
            return expense
        }

        return "\(expense)・収入 \(AmountText.text(day.incomeTotal))"
    }
}
