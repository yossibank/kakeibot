import DesignSystem
import SwiftUI

struct EntryItemHelp: View {
    @State private var isShown = false

    let onClose: () -> Void

    var body: some View {
        let scale: CGFloat = isShown ? 1 : 0.94

        ZStack {
            Palette.scrim
                .opacity(0.55)
                .ignoresSafeArea()
                .onTapGesture(perform: onClose)

            VStack(spacing: 16) {
                SheetTitle("品目の使い方")

                EntryReceiptRule(style: .dashed)

                VStack(alignment: .leading, spacing: 16) {
                    ForEach(Self.steps, id: \.title) { step in
                        stepRow(step)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                EntryReceiptRule(style: .double)

                PrimaryButton("分かりました", action: onClose)
            }
            .padding(.horizontal, 24)
            .padding(.top, 32)
            .padding(.bottom, 28)
            .frame(maxWidth: Self.maxWidth)
            .background {
                EntryReceiptShape(tooth: 12, hasTopEdge: true)
                    .fill(Palette.card)
                    .shadow(color: Palette.shadow.opacity(0.5), radius: 30, y: 14)
            }
            .padding(.horizontal, 24)
            .scaleEffect(scale)
        }
        .transition(.opacity)
        .onAppear {
            withAnimation(.snappy(duration: 0.25)) {
                isShown = true
            }
        }
    }
}

private extension EntryItemHelp {
    struct Step {
        let systemImage: String
        let title: String
        let detail: String
    }

    func stepRow(_ step: Step) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: step.systemImage)
                .sansFont(.caption, weight: .semibold)
                .foregroundStyle(Palette.accent)
                .frame(width: Self.markSize, height: Self.markSize)
                .overlay {
                    Circle()
                        .stroke(Palette.accent.opacity(.medium), lineWidth: 1)
                }

            VStack(alignment: .leading, spacing: 2) {
                Text(step.title)
                    .textFont(.subheadline, weight: .semibold)
                    .foregroundStyle(Palette.accentStrong)

                Text(step.detail)
                    .textFont(.footnote)
                    .foregroundStyle(Palette.subtext)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

private extension EntryItemHelp {
    static let maxWidth: CGFloat = 340
    static let markSize: CGFloat = 32

    static let steps = [
        Step(systemImage: "plus", title: "追加", detail: "「＋ 品目を追加」から、品名と単価・数量を入れます。"),
        Step(systemImage: "hand.tap", title: "変更", detail: "品目を押すと、伝票で直せます。"),
        Step(systemImage: "arrow.left", title: "削除", detail: "品目を左に滑らせると、削除できます。"),
        Step(systemImage: "tag", title: "値引・半額", detail: "「値引」で値引の行に、「半額」で単価を半分にできます。"),
        Step(systemImage: "equal", title: "調整", detail: "差額が出た時は、合計を品目の合計にそろえます。")
    ]
}

#Preview {
    EntryItemHelp {}
        .background(Palette.background)
}
