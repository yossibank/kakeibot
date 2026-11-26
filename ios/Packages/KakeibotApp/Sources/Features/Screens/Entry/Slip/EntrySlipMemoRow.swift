import DesignSystem
import FeatureModels
import SwiftUI

struct EntrySlipMemoRow: View {
    @Environment(\.isPro) private var isPro

    let model: EntryModel
    let isMemoActive: Bool
    let height: CGFloat
    let onMemo: () -> Void
    let onOpenItems: () -> Void
    let onReceipt: (() -> Void)?
    let onVoice: (() -> Void)?

    var body: some View {
        HStack(spacing: 8) {
            Button(action: onMemo) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Image(systemName: "pencil")
                        .textFont(.caption, weight: .semibold)

                    Text(memoText)
                        .textFont(.footnote)
                        .underline(
                            model.output.isMemoFromVoice,
                            color: Palette.accent.opacity(.medium)
                        )
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .foregroundStyle(memoColor)
                .frame(maxHeight: .infinity)
                .contentShape(.rect)
            }
            .buttonStyle(.plain)

            if showsItems {
                EntryItemButton(
                    count: model.state.items.list.count,
                    total: model.output.itemTotal,
                    adjustment: model.output.itemAdjustment,
                    onOpen: onOpenItems
                )
                .fixedSize()
            }

            if let onReceipt {
                quickButton("doc.text.viewfinder", action: onReceipt)
                    .overlay(alignment: .topTrailing) {
                        if let receiptsLeft {
                            receiptBadge(receiptsLeft)
                        }
                    }
            }

            if let onVoice {
                quickButton("mic", action: onVoice)
            }
        }
        .padding(.leading, 16)
        .padding(.trailing, 12)
        .frame(height: height)
    }
}

private extension EntrySlipMemoRow {
    func quickButton(
        _ systemImage: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .textFont(.footnote, weight: .semibold)
                .foregroundStyle(Palette.accent)
                .frame(width: Self.quickSize, height: Self.quickSize)
                .overlay {
                    Circle()
                        .stroke(Palette.accent.opacity(.medium), lineWidth: 1)
                }
                .contentShape(.circle)
        }
        .buttonStyle(.plain)
    }

    func receiptBadge(_ left: Int) -> some View {
        let fill = left > 0 ? Palette.accent : Palette.amber

        return Text("\(left)")
            .sansFont(.micro, weight: .bold)
            .monospacedDigit()
            .foregroundStyle(Palette.backgroundBottom)
            .frame(minWidth: Self.badgeSize, minHeight: Self.badgeSize)
            .background(fill, in: .capsule)
            .offset(x: 4, y: -4)
            .allowsHitTesting(false)
    }
}

private extension EntrySlipMemoRow {
    static let quickSize: CGFloat = 32
    static let badgeSize: CGFloat = 16

    var memoText: String {
        model.state.memo.isEmpty ? "\(model.output.memoPrompt)をメモ" : model.state.memo
    }

    var memoColor: Color {
        if isMemoActive {
            return Palette.accent
        }

        return model.state.memo.isEmpty ? Palette.hint : Palette.subtext
    }

    var showsItems: Bool {
        model.output.showsItems && !model.state.items.list.isEmpty
    }

    var receiptsLeft: Int? {
        isPro ? nil : model.output.freeReceiptsLeft
    }
}
