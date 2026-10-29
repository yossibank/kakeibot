import Core
import DesignSystem
import SwiftUI

extension RecordsView {
    func selectionBar(_ selection: Set<Entry.ID>) -> some View {
        let type = model.batchType(of: selection)
        let canChangeWallet = !selection.isEmpty && !model.hasTransfer(in: selection)

        return HStack(spacing: 4) {
            Text("\(selection.count) 件")
                .textFont(.subheadline)
                .monospacedDigit()
                .foregroundStyle(Palette.accentStrong)
                .padding(.leading, 8)

            Spacer(minLength: 4)

            barButton(
                "カテゴリ",
                systemImage: "tag",
                isEnabled: type != nil
            ) {
                if let type {
                    batchTarget = .category(type)
                }
            }

            barButton(
                "口座",
                systemImage: "building.columns",
                isEnabled: canChangeWallet
            ) {
                batchTarget = .wallet
            }

            barButton(
                "削除",
                systemImage: "trash",
                isEnabled: !selection.isEmpty,
                tint: Palette.rose
            ) {
                model.requestDelete(Array(selection)) { ids in
                    onDeleteEntries(ids)
                    finishSelecting()
                }
            }
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
    func barButton(
        _ title: String,
        systemImage: String,
        isEnabled: Bool,
        tint: Color = Palette.accent,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .textFont(.footnote)
                .foregroundStyle(tint)
                .padding(.horizontal, 8)
                .frame(minHeight: 44)
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.4)
    }
}
