import Core
import DesignSystem
import FeatureModels
import SwiftUI

extension RecordsView {
    func selectionBar(_ selection: Set<Entry.ID>) -> some View {
        let type = model.output.batchType(of: selection)

        return ViewThatFits(in: .horizontal) {
            barContent(
                selection,
                type: type,
                isCompact: false,
                isStacked: false
            )

            barContent(
                selection,
                type: type,
                isCompact: false,
                isStacked: true
            )

            barContent(
                selection,
                type: type,
                isCompact: true,
                isStacked: true
            )
        }
        .padding(.horizontal, 8)
        .frame(minHeight: 56)
        .background(Palette.field, in: .capsule)
        .overlay {
            Capsule()
                .stroke(Palette.outline, lineWidth: 1)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 12)
    }
}

private extension RecordsView {
    func barContent(
        _ selection: Set<Entry.ID>,
        type: Entry.Kind?,
        isCompact: Bool,
        isStacked: Bool
    ) -> some View {
        HStack(spacing: 4) {
            selectAll(selection, isCompact: isCompact)

            Spacer(minLength: 4)

            barButtons(
                selection,
                type: type,
                isStacked: isStacked
            )
        }
    }

    func selectAll(
        _ selection: Set<Entry.ID>,
        isCompact: Bool
    ) -> some View {
        let selectsAll = model.output.selectsAllShown(selection)
        let title = selectsAll ? "すべて外す" : "すべて選ぶ"
        let systemImage = selectsAll ? "xmark" : "checkmark"

        return HStack(spacing: 8) {
            Text("\(selection.count) 件")
                .textFont(.subheadline, weight: .semibold)
                .monospacedDigit()
                .foregroundStyle(Palette.accentStrong)
                .lineLimit(1)
                .fixedSize()

            ChipButton(isSelected: selectsAll) {
                model.state.select(selectsAll ? [] : model.output.selectingAllShown(in: selection))
            } content: {
                HStack(spacing: 4) {
                    Image(systemName: systemImage)

                    if !isCompact {
                        Text(title)
                    }
                }
                .lineLimit(1)
            }
            .fixedSize()
            .disabled(model.output.shownEntryIDs.isEmpty)
        }
        .padding(.leading, 8)
        .animation(.snappy, value: selectsAll)
    }

    func barButtons(
        _ selection: Set<Entry.ID>,
        type: Entry.Kind?,
        isStacked: Bool
    ) -> some View {
        HStack(spacing: 4) {
            barButton(
                "カテゴリ",
                systemImage: "tag",
                block: model.output.batchCategoryBlock(of: selection),
                isStacked: isStacked
            ) {
                if let type {
                    model.state.present(.batch(.category(type)))
                }
            }

            barButton(
                "口座",
                systemImage: "building.columns",
                block: model.output.batchWalletBlock(of: selection),
                isStacked: isStacked
            ) {
                model.state.present(.batch(.wallet))
            }

            barButton(
                "削除",
                systemImage: "trash",
                block: model.output.batchDeleteBlock(of: selection),
                isStacked: isStacked,
                tint: Palette.rose
            ) {
                model.state.requestDelete(Array(selection)) { ids in
                    onDeleteEntries(ids)
                    finishSelecting()
                }
            }
        }
    }

    func barButton(
        _ title: String,
        systemImage: String,
        block: String?,
        isStacked: Bool,
        tint: Color = Palette.accent,
        action: @escaping () -> Void
    ) -> some View {
        let opacity = block == nil ? 1 : 0.4

        return Button {
            if let block {
                model.state.notices.error.inform(block)
            } else {
                action()
            }
        } label: {
            Group {
                if isStacked {
                    VStack(spacing: 2) {
                        Image(systemName: systemImage)
                            .sansFont(.body, weight: .semibold)

                        Text(title)
                            .textFont(size: .caption)
                    }
                    .frame(minWidth: 44)
                } else {
                    Label(title, systemImage: systemImage)
                        .textFont(.subheadline, weight: .medium)
                }
            }
            .lineLimit(1)
            .fixedSize()
            .foregroundStyle(tint)
            .padding(.horizontal, 8)
            .frame(minHeight: 44)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .opacity(opacity)
    }
}
