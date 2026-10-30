import Core
import DesignSystem
import Store
import SwiftUI

struct StampTallyCard: View {
    let tallies: [StampCalendar.Tally]
    let emptyText: String
    let onOpen: (StampCalendar.Tally) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            CardHeader("押したスタンプ")

            if tallies.isEmpty {
                Text(emptyText)
                    .textFont(.footnote)
                    .foregroundStyle(Palette.subtext)
            } else {
                LazyVGrid(columns: Self.columns, alignment: .leading) {
                    ForEach(tallies) { tally in
                        Button {
                            onOpen(tally)
                        } label: {
                            HStack(spacing: 8) {
                                IconSeal(tally.icon, size: 28)

                                Text("×\(tally.count)")
                                    .displayFont(.body)
                                    .monospacedDigit()
                                    .foregroundStyle(Palette.accentStrong)
                            }
                            .contentShape(.rect)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .card()
    }
}

private extension StampTallyCard {
    static let columns = [
        GridItem(.adaptive(minimum: 72), spacing: 12, alignment: .leading)
    ]
}
