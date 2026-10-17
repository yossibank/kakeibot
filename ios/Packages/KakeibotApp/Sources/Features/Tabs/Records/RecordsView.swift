import Core
import DesignSystem
import SwiftUI

struct RecordsView: View {
    @Bindable var model: RecordsModel

    @State private var openId: Entry.ID?
    @State private var isMovingForward = true

    let onOpenEntry: (Entry.ID) -> Void
    let onDelete: (Entry.ID) -> Void

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                header

                ZStack(alignment: .top) {
                    monthContent
                        .id(model.month)
                        .transition(.page(forward: isMovingForward))
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
        .onPageSwipe { direction in
            moveMonth(direction)
        }
        .sensoryFeedback(.selection, trigger: model.month)
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

                Text(model.periodText)
                    .font(.system(size: 10))
                    .monospacedDigit()
                    .foregroundStyle(Palette.mist)
            }

            monthButton(systemImage: "chevron.right", months: 1)
        }
    }

    var monthContent: some View {
        VStack(spacing: 12) {
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
                type: row.type
            )
        }
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

    func moveMonth(_ direction: PageSwipeDirection) {
        switch direction {
        case .forward: move(months: 1)
        case .backward: move(months: -1)
        }
    }

    func move(months: Int) {
        openId = nil
        isMovingForward = months > 0

        withAnimation(.snappy) {
            model.move(months: months)
        }
    }
}
