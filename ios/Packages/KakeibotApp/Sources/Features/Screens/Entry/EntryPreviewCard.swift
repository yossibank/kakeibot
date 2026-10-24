import Core
import DesignSystem
import SwiftUI

struct EntryPreviewCard: View {
    @Binding var memoFrame: CGRect

    @Environment(\.themeStyle.corner) private var corner

    let model: EntryModel
    let isActive: Bool
    let today: LocalDate
    let onAmount: () -> Void
    let onDate: () -> Void
    let onWallet: () -> Void
    let onMemo: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(model.typeName)
                    .displayFont(.caption)
                    .tracking(5)
                    .foregroundStyle(Palette.accent)

                Spacer()

                Button(action: onDate) {
                    HStack(spacing: 4) {
                        Text(EntryModel.dateText(for: model.date, today: today))

                        Image(systemName: "chevron.right")
                    }
                    .textFont(.caption)
                    .foregroundStyle(Palette.accent)
                    .frame(minHeight: 32)
                    .contentShape(.rect)
                }
            }

            Button(action: onAmount) {
                VStack(spacing: 4) {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(AmountText.text(model.amount))
                            .displayFont(.display, weight: .semibold)
                            .monospacedDigit()
                            .foregroundStyle(Palette.accentStrong)
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)

                        Image(systemName: "pencil")
                            .sansFont(.body)
                            .foregroundStyle(Palette.accent)
                    }

                    Text(note)
                        .textFont(.caption2)
                        .foregroundStyle(Palette.subtext)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                .frame(maxWidth: .infinity)
                .padding(.bottom, 12)
                .contentShape(.rect)
            }

            preview
                .padding(.vertical, 4)
                .overlay(alignment: .top) {
                    divider
                }
                .overlay(alignment: .bottom) {
                    divider
                }

            HStack(spacing: 8) {
                if model.type != .transfer {
                    footerButton(
                        model.walletName,
                        systemImage: "wallet.bifold",
                        action: onWallet
                    )
                }

                Spacer(minLength: 0)

                footerButton(
                    memoTitle,
                    systemImage: "square.and.pencil",
                    action: onMemo
                )
                .onGeometryChange(for: CGRect.self) { proxy in
                    proxy.frame(in: .named(EntrySheet.coordinateSpace))
                } action: { frame in
                    memoFrame = frame
                }
            }
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .card()
        .overlay {
            RoundedRectangle(cornerRadius: corner.radius(22))
                .strokeBorder(border, lineWidth: 1.2)
        }
    }
}

private extension EntryPreviewCard {
    @ViewBuilder
    var preview: some View {
        if model.type != .transfer, model.selectedCategory == nil {
            HStack(spacing: 12) {
                Image(systemName: "circle.dashed")
                    .sansFont(.body, weight: .light)
                    .frame(width: 21, height: 21)

                Text("カテゴリを選んでください")
                    .textFont(.subheadline)

                Spacer(minLength: 0)
            }
            .foregroundStyle(Palette.hint)
            .frame(minHeight: 48)
        } else {
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
        }
    }

    var divider: some View {
        Rectangle()
            .fill(Palette.accent.opacity(.soft))
            .frame(height: 1)
    }

    func footerButton(
        _ title: String,
        systemImage: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Label(title, systemImage: systemImage)
                    .lineLimit(1)

                Image(systemName: "chevron.right")
                    .sansFont(.micro, weight: .bold)
            }
            .textFont(.footnote)
            .foregroundStyle(Palette.accent)
            .frame(minHeight: 44)
            .contentShape(.rect)
        }
    }
}

private extension EntryPreviewCard {
    var note: String {
        if let expression = model.expressionText {
            return expression
        }

        if isActive {
            return "入力中"
        }

        return model.amount == 0 ? "タップして入力" : "タップして直す"
    }

    var memoTitle: String {
        model.memo.isEmpty ? "メモを書く" : "メモを直す"
    }

    var border: Color {
        isActive ? Palette.accent : Color.clear
    }
}
