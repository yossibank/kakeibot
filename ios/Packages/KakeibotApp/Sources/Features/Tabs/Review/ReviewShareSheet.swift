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
                    .font(.serif(.body))
                    .foregroundStyle(Palette.accent)

                Spacer()

                Color.clear
                    .frame(width: 44, height: 44)
            }

            HStack(spacing: 12) {
                badge

                Text(share.name)
                    .font(.headline)
                    .foregroundStyle(Palette.accentLight)

                Spacer()

                Text(AmountText.text(share.amount))
                    .font(.serif(.headline))
                    .monospacedDigit()
                    .foregroundStyle(Palette.accentLight)
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
                                type: row.type,
                                isRecurring: row.isRecurring
                            )
                            .contentShape(.rect)
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
                .fill(Palette.background)
                .ignoresSafeArea()
        }
        .preferredColorScheme(.dark)
    }
}

private extension ReviewShareSheet {
    @ViewBuilder
    var badge: some View {
        if share.id == ReviewModel.recurringShareId {
            IconBadge(systemImage: "repeat", size: 40)
        } else {
            IconBadge(share.icon, size: 40)
        }
    }
}
