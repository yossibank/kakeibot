import Core
import DesignSystem
import Store
import SwiftUI

struct StampDaysSheet: View {
    @Environment(\.dismiss) private var dismiss

    let tally: StampCalendar.Tally
    let periodTitle: String
    let days: [LocalDate]
    let entryDay: (LocalDate) -> EntryDay?
    let onOpen: (LocalDate) -> Void

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                RingButton(systemImage: "xmark") {
                    dismiss()
                }

                Spacer()

                Text(periodTitle)
                    .displayFont(.body)
                    .foregroundStyle(Palette.accent)

                Spacer()

                Color.clear
                    .frame(width: 44, height: 44)
            }

            HStack(spacing: 12) {
                IconSeal(tally.icon, size: 40)

                Text("押した日")
                    .textFont(.headline)
                    .foregroundStyle(Palette.accentStrong)

                Spacer()

                Text("×\(tally.count)")
                    .displayFont(.headline)
                    .monospacedDigit()
                    .foregroundStyle(Palette.accentStrong)
            }
            .padding(.horizontal, 4)

            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(days, id: \.self) { date in
                        Button {
                            onOpen(date)
                        } label: {
                            row(date)
                        }
                        .buttonStyle(.plain)
                        .overlay(alignment: .top) {
                            Hairline(thickness: 1)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .card()
            }
            .scrollIndicators(.hidden)
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background {
            Backdrop()
                .ignoresSafeArea()
        }
    }
}

private extension StampDaysSheet {
    func row(_ date: LocalDate) -> some View {
        let day = entryDay(date)

        return HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text("\(date.month)/\(date.day)")
                .displayFont(.body)
                .foregroundStyle(Palette.accentStrong)

            Text("（\(date.weekday.shortName)）")
                .textFont(.caption)
                .foregroundStyle(Palette.subtext)

            Spacer(minLength: 8)

            if let day,
               day.expenseTotal > 0 {
                AmountText(day.expenseTotal, type: .expense, font: .style(.caption))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }

            if let day,
               day.incomeTotal > 0 {
                AmountText(day.incomeTotal, type: .income, font: .style(.caption))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }

            Image(systemName: "chevron.right")
                .sansFont(.small)
                .foregroundStyle(Palette.hint)
        }
        .frame(minHeight: 48)
        .contentShape(.rect)
    }
}
