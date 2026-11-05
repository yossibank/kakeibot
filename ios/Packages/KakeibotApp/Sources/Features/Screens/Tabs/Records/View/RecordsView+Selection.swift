import Core
import DesignSystem
import SwiftUI

extension RecordsView {
    func selectionBar(_ selection: Set<Entry.ID>) -> some View {
        let type = model.batchType(of: selection)
        let canChangeWallet = !selection.isEmpty && !model.hasTransfer(in: selection)

        return ViewThatFits(in: .horizontal) {
            barContent(
                selection,
                type: type,
                canChangeWallet: canChangeWallet,
                isCompact: false,
                isStacked: false
            )

            barContent(
                selection,
                type: type,
                canChangeWallet: canChangeWallet,
                isCompact: false,
                isStacked: true
            )

            barContent(
                selection,
                type: type,
                canChangeWallet: canChangeWallet,
                isCompact: true,
                isStacked: true
            )
        }
        .padding(.horizontal, 8)
        .frame(minHeight: 56)
        .background(Palette.panel, in: .capsule)
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
        canChangeWallet: Bool,
        isCompact: Bool,
        isStacked: Bool
    ) -> some View {
        HStack(spacing: 4) {
            selectAll(selection, isCompact: isCompact)

            Spacer(minLength: 4)

            barButtons(
                selection,
                type: type,
                canChangeWallet: canChangeWallet,
                isStacked: isStacked
            )
        }
    }

    func selectAll(
        _ selection: Set<Entry.ID>,
        isCompact: Bool
    ) -> some View {
        let selectsAll = model.selectsAllShown(selection)
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
                self.selection = selectsAll ? [] : model.selectingAllShown(in: selection)
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
            .disabled(model.shownEntryIDs.isEmpty)
        }
        .padding(.leading, 8)
        .animation(.snappy, value: selectsAll)
    }

    func barButtons(
        _ selection: Set<Entry.ID>,
        type: Entry.Kind?,
        canChangeWallet: Bool,
        isStacked: Bool
    ) -> some View {
        HStack(spacing: 4) {
            barButton(
                "カテゴリ",
                systemImage: "tag",
                isEnabled: type != nil,
                isStacked: isStacked
            ) {
                if let type {
                    batchTarget = .category(type)
                }
            }

            barButton(
                "口座",
                systemImage: "building.columns",
                isEnabled: canChangeWallet,
                isStacked: isStacked
            ) {
                batchTarget = .wallet
            }

            barButton(
                "削除",
                systemImage: "trash",
                isEnabled: !selection.isEmpty,
                isStacked: isStacked,
                tint: Palette.rose
            ) {
                model.requestDelete(Array(selection)) { ids in
                    onDeleteEntries(ids)
                    finishSelecting()
                }
            }
        }
    }

    func barButton(
        _ title: String,
        systemImage: String,
        isEnabled: Bool,
        isStacked: Bool,
        tint: Color = Palette.accent,
        action: @escaping () -> Void
    ) -> some View {
        let opacity = isEnabled ? 1 : 0.4

        return Button(action: action) {
            Group {
                if isStacked {
                    VStack(spacing: 2) {
                        Image(systemName: systemImage)
                            .sansFont(.small, weight: .semibold)

                        Text(title)
                            .textFont(size: .micro)
                    }
                    .frame(minWidth: 44)
                } else {
                    Label(title, systemImage: systemImage)
                        .textFont(.footnote)
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
        .disabled(!isEnabled)
        .opacity(opacity)
    }
}
