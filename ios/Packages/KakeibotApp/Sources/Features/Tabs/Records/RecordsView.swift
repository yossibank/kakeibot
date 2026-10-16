import Core
import DesignSystem
import SwiftUI

struct RecordsView: View {
    @Bindable var model: RecordsModel

    @State private var swipe: Swipe?

    let onOpenEntry: (Entry.ID) -> Void
    let onDelete: (EntryChange) -> Void

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
                swipeRow(row)
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 4)
        .card()
    }

    func swipeRow(_ row: EntryRowItem) -> some View {
        let offset = swipe?.id == row.id ? swipe?.offset ?? 0 : 0
        let reveal = min(-offset / Self.deleteWidth, 1)

        return ZStack(alignment: .trailing) {
            Button {
                Task {
                    await delete(row)
                }
            } label: {
                Text("消す")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Palette.rose)
                    .frame(width: Self.deleteWidth - 12, height: 40)
                    .background(Palette.rose.opacity(0.12), in: Capsule())
                    .overlay {
                        Capsule()
                            .stroke(Palette.rose.opacity(0.6), lineWidth: 1)
                    }
            }
            .buttonStyle(.plain)
            .opacity(reveal)

            Button {
                tap(row)
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
            .offset(x: offset)
            .gesture(
                SwipeGesture { x in
                    move(row, by: x)
                } onEnd: { _ in
                    end(row)
                }
            )
        }
        .clipped()
        .overlay(alignment: .top) {
            Rectangle()
                .fill(Palette.gold.opacity(0.1))
                .frame(height: 1)
        }
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

            if let total = Self.totalText(for: day) {
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
    struct Swipe {
        let id: Entry.ID
        let offset: CGFloat
        let isOpen: Bool
    }

    static let deleteWidth: CGFloat = 76

    static func weekdayColor(for date: LocalDate) -> Color {
        if Holiday.contains(date) || date.weekday == .sunday {
            return Palette.holiday
        }

        return date.weekday == .saturday ? Palette.saturday : Palette.mist
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
}

private extension RecordsView {
    func tap(_ row: EntryRowItem) {
        guard swipe == nil else {
            withAnimation(.snappy) {
                swipe = nil
            }

            return
        }

        onOpenEntry(row.id)
    }

    func move(
        _ row: EntryRowItem,
        by x: CGFloat
    ) {
        let isOpen = swipe?.id == row.id && swipe?.isOpen == true
        let start = isOpen ? -Self.deleteWidth : 0
        let raw = min(start + x, 0)
        let over = min(raw + Self.deleteWidth, 0)
        let offset = max(raw, -Self.deleteWidth) + over / 3

        swipe = Swipe(id: row.id, offset: offset, isOpen: isOpen)
    }

    func end(_ row: EntryRowItem) {
        let offset = swipe?.offset ?? 0
        let opens = offset < -Self.deleteWidth / 2

        withAnimation(.snappy) {
            swipe = opens
                ? Swipe(id: row.id, offset: -Self.deleteWidth, isOpen: true)
                : nil
        }
    }

    func delete(_ row: EntryRowItem) async {
        withAnimation(.snappy) {
            swipe = nil
        }

        if let change = await model.delete(row.id) {
            onDelete(change)
        }
    }
}
