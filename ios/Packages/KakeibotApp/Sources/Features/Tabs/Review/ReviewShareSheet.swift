import Core
import DesignSystem
import SwiftUI

struct ReviewShareSheet: View {
    @Environment(\.dismiss) private var dismiss

    let share: ReviewModel.Share
    let periodTitle: String
    let rows: [EntryRowItem]
    let onOpen: (Entry.ID) -> Void

    var body: some View {
        VStack(spacing: 14) {
            HStack {
                RingButton(systemImage: "xmark") {
                    dismiss()
                }

                Spacer()

                Text(periodTitle)
                    .font(.system(size: 15, design: .serif))
                    .foregroundStyle(Palette.gold)

                Spacer()

                Color.clear
                    .frame(width: 44, height: 44)
            }

            HStack(spacing: 12) {
                IconBadge(share.icon, size: 40)

                Text(share.name)
                    .font(.headline)
                    .foregroundStyle(Palette.champagne)

                Spacer()

                Text(AmountText.text(share.amount))
                    .font(.system(size: 22, design: .serif))
                    .monospacedDigit()
                    .foregroundStyle(Palette.champagne)
            }
            .padding(.horizontal, 4)

            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(rows) { row in
                        Button {
                            onOpen(row.id)
                        } label: {
                            EntryRow(
                                icon: row.icon,
                                title: row.title,
                                tag: row.tag,
                                detail: row.detail,
                                amount: row.amount,
                                type: row.type
                            )
                            .contentShape(.rect)
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
