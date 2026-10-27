import Core
import DesignSystem
import SwiftUI

struct RecurringRowCard: View {
    let row: RecurringListModel.Row
    let isPaused: Bool

    init(
        row: RecurringListModel.Row,
        isPaused: Bool = false
    ) {
        self.row = row
        self.isPaused = isPaused
    }

    var body: some View {
        HStack(spacing: 12) {
            IconBadge(row.icon, size: 38)

            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline) {
                    Text(row.title)
                        .textFont(.subheadline)
                        .foregroundStyle(Palette.text)
                        .lineLimit(2)

                    Spacer(minLength: 8)

                    AmountText(row.amount, type: row.type)
                }

                Text(row.schedule)
                    .textFont(.caption)
                    .foregroundStyle(Palette.subtext)
                    .lineLimit(1)

                HStack(alignment: .firstTextBaseline) {
                    if let place = row.place {
                        Text(place)
                            .textFont(.caption)
                            .foregroundStyle(Palette.subtext)
                            .lineLimit(1)
                    }

                    Spacer(minLength: 8)

                    if isPaused {
                        Label("止めています", systemImage: "pause.circle")
                            .textFont(.caption2)
                            .foregroundStyle(Palette.amber)
                    } else {
                        Text(nextText)
                            .textFont(.caption2)
                            .foregroundStyle(Palette.subtext)
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .frame(maxHeight: .infinity)
        .contentShape(.rect)
        .card()
    }
}

extension RecurringRowCard {
    static let height: CGFloat = 84
}

private extension RecurringRowCard {
    var nextText: String {
        guard let date = row.next else {
            return "終わりました"
        }

        let next = "次は \(date.month)/\(date.day)"

        return [row.closing, next].compactMap(\.self).joined(separator: "・")
    }
}
