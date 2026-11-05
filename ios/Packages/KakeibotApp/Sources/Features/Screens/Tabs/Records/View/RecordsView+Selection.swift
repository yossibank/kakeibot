import Core
import DesignSystem
import SwiftUI

extension RecordsView {
    func selectionBar(_ selection: Set<Entry.ID>) -> some View {
        let type = model.batchType(of: selection)
        let canChangeWallet = !selection.isEmpty && !model.hasTransfer(in: selection)

        return HStack(spacing: 4) {
            countMenu(selection)

            Spacer(minLength: 4)

            ViewThatFits(in: .horizontal) {
                barButtons(
                    selection,
                    type: type,
                    canChangeWallet: canChangeWallet,
                    isStacked: false
                )

                barButtons(
                    selection,
                    type: type,
                    canChangeWallet: canChangeWallet,
                    isStacked: true
                )
            }
            .layoutPriority(1)
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
    func countMenu(_ selection: Set<Entry.ID>) -> some View {
        let shownCount = model.shownEntryIDs.count

        return Menu {
            Button {
                self.selection = model.selectingAllShown(in: selection)
            } label: {
                Label("表示中の \(shownCount) 件をすべて選ぶ", systemImage: "checkmark.circle")
            }
            .disabled(model.selectsAllShown(selection))

            Button {
                self.selection = []
            } label: {
                Label("すべて外す", systemImage: "circle")
            }
            .disabled(selection.isEmpty)
        } label: {
            HStack(spacing: 4) {
                Text("\(selection.count) 件")
                    .textFont(.subheadline)
                    .monospacedDigit()

                Image(systemName: "chevron.down")
                    .sansFont(.caption, weight: .semibold)
            }
            .foregroundStyle(Palette.accentStrong)
            .lineLimit(1)
            .fixedSize()
            .padding(.leading, 8)
            .frame(minHeight: 44)
            .contentShape(.rect)
        }
        .menuOrder(.fixed)
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
