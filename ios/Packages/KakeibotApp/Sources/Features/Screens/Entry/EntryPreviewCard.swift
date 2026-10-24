import Core
import DesignSystem
import SwiftUI

struct EntryPreviewCard: View {
    @Environment(\.themeStyle.corner) private var corner

    let model: EntryModel
    let isActive: Bool
    let today: LocalDate

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text(model.typeName)
                    .displayFont(.caption)
                    .tracking(5)
                    .foregroundStyle(Palette.accent)

                Spacer()

                Text(EntryModel.dateText(for: model.date, today: today))
                    .textFont(.caption)
                    .foregroundStyle(Palette.subtext)
            }

            VStack(spacing: 4) {
                Text(AmountText.text(model.amount))
                    .displayFont(.display, weight: .semibold)
                    .monospacedDigit()
                    .foregroundStyle(Palette.accentStrong)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)

                Text(note)
                    .textFont(.caption2)
                    .foregroundStyle(Palette.subtext)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)

            EntryRow(
                icon: model.previewIcon,
                title: model.previewTitle,
                tag: model.previewTag,
                detail: model.previewDetail,
                memo: model.previewMemo,
                amount: model.amount,
                type: model.type,
                foldsMemo: false
            )
            .padding(.top, 4)
            .overlay(alignment: .top) {
                Rectangle()
                    .fill(Palette.accent.opacity(.soft))
                    .frame(height: 1)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 14)
        .padding(.bottom, 4)
        .card()
        .overlay {
            RoundedRectangle(cornerRadius: corner.radius(22))
                .strokeBorder(border, lineWidth: 1.2)
        }
        .contentShape(.rect)
    }
}

private extension EntryPreviewCard {
    var note: String {
        model.expressionText ?? (isActive ? "入力中" : "タップして入力")
    }

    var border: Color {
        isActive ? Palette.accent : Color.clear
    }
}
