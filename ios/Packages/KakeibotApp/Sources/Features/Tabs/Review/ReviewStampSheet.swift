import Core
import DesignSystem
import Store
import SwiftUI

struct ReviewStampSheet: View {
    @Environment(\.dismiss) private var dismiss

    let tally: StampCalendar.Tally
    let periodTitle: String
    let days: [LocalDate]
    let entryDay: (LocalDate) -> EntryDay?
    let onOpen: (LocalDate) -> Void

    var body: some View {
        VStack(spacing: 14) {
            HStack {
                RingButton(systemImage: "xmark") {
                    dismiss()
                }

                Spacer()

                Text(periodTitle)
                    .font(.serif(.body))
                    .foregroundStyle(Palette.gold)

                Spacer()

                Color.clear
                    .frame(width: 44, height: 44)
            }

            HStack(spacing: 12) {
                IconSeal(tally.icon, size: 40)

                Text("押した日")
                    .font(.headline)
                    .foregroundStyle(Palette.champagne)

                Spacer()

                Text("×\(tally.count)")
                    .font(.serif(.headline))
                    .monospacedDigit()
                    .foregroundStyle(Palette.champagne)
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
        .padding(.horizontal, 18)
        .padding(.top, 18)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background {
            Rectangle()
                .fill(Palette.night)
                .ignoresSafeArea()
        }
        .preferredColorScheme(.dark)
    }
}

private extension ReviewStampSheet {
    func row(_ date: LocalDate) -> some View {
        let day = entryDay(date)

        return HStack(alignment: .firstTextBaseline, spacing: 6) {
            Text("\(date.month)/\(date.day)")
                .font(.serif(.body))
                .foregroundStyle(Palette.champagne)

            Text("（\(date.weekday.shortName)）")
                .font(.caption)
                .foregroundStyle(Palette.mist)

            Spacer(minLength: 8)

            if let day, day.expenseTotal > 0 {
                AmountText(day.expenseTotal, type: .expense)
                    .font(.caption)
            }

            if let day, day.incomeTotal > 0 {
                AmountText(day.incomeTotal, type: .income)
                    .font(.caption)
            }

            Image(systemName: "chevron.right")
                .font(.caption2)
                .foregroundStyle(Palette.dusk)
        }
        .frame(minHeight: 48)
        .contentShape(.rect)
    }
}
