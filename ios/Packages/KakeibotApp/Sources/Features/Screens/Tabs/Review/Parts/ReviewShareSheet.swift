import Core
import DesignSystem
import FeatureModels
import SwiftUI

struct ReviewShareSheet: View {
    @Environment(\.dismiss) private var dismiss

    let share: ReviewModel.Share
    let periodTitle: String
    let rows: [EntryRowItem]
    let onOpen: (Entry.ID) -> Void

    var body: some View {
        VStack(spacing: 16) {
            SheetHeader {
                dismiss()
            } title: {
                Text(periodTitle)
                    .displayFont(.body)
                    .foregroundStyle(Palette.accent)
            }

            summary

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
                                route: row.route,
                                memo: row.memo,
                                amount: row.amount,
                                type: row.type,
                                isRecurring: row.isRecurring
                            )
                            .contentShape(.rect)
                        }
                        .buttonStyle(.plain)
                        .topHairline()
                    }
                }
                .padding(.horizontal, 16)
                .card()
                .sharesTextScale(id: rows)
            }
            .scrollIndicators(.hidden)
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .backdrop()
        .presentationSizing(.tallForm)
    }
}

private extension ReviewShareSheet {
    var summary: some View {
        HStack(spacing: 12) {
            badge

            Text(share.name)
                .textFont(.headline)
                .foregroundStyle(Palette.accentStrong)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Spacer()

            AmountText(share.amount, font: .size(.headline), color: Palette.accentStrong)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
        }
        .padding(.horizontal, 4)
    }

    @ViewBuilder
    var badge: some View {
        switch share.id {
        case .recurring:
            IconBadge(systemImage: "repeat", size: 40)
        case .month:
            IconBadge(systemImage: "calendar", size: 40)
        case .category, .wallet, .move, .factor:
            IconBadge(share.icon, size: 40)
        }
    }
}
