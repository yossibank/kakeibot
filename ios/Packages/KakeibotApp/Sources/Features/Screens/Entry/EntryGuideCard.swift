import DesignSystem
import SwiftUI

struct EntryGuideCard: View {
    @State private var isShown = false

    var onConfirm: (() -> Void)?

    let guide: Guide
    let onClose: () -> Void

    var body: some View {
        let scale: CGFloat = isShown ? 1 : 0.94

        ZStack {
            Palette.scrim
                .opacity(0.55)
                .ignoresSafeArea()
                .onTapGesture(perform: onClose)

            VStack(spacing: 16) {
                SheetTitle(guide.title)

                EntryReceiptRule(style: .dashed)

                VStack(alignment: .leading, spacing: 16) {
                    ForEach(guide.steps, id: \.title) { step in
                        stepRow(step)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                EntryReceiptRule(style: .double)

                PrimaryButton(guide.buttonTitle, action: onConfirm ?? onClose)
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

extension EntryGuideCard {
    struct Guide {
        let title: String
        let steps: [Step]
        let buttonTitle: String
    }

    struct Step {
        let systemImage: String
        let title: String
        let detail: String
    }
}

extension EntryGuideCard.Guide {
    static let items = Self(
        title: "品目の使い方",
        steps: [
            .init(systemImage: "plus", title: "追加", detail: "「＋ 品目を追加」から、品名と単価・数量を入れます。"),
            .init(systemImage: "hand.tap", title: "変更", detail: "品目を押すと、伝票で直せます。"),
            .init(systemImage: "arrow.left", title: "削除", detail: "品目を左に滑らせると、削除できます。"),
            .init(systemImage: "tag", title: "値引・半額", detail: "「値引」で値引の行に、「半額」で単価を半分にできます。"),
            .init(systemImage: "equal", title: "調整", detail: "差額が出た時は、合計を品目の合計にそろえます。")
        ],
        buttonTitle: "分かりました"
    )

    static let receipt = Self(
        title: "レシートの撮り方",
        steps: [
            .init(
                systemImage: "rectangle.portrait",
                title: "平らな所に置く",
                detail: "折れやしわを伸ばし、机などに置いて撮ります。"
            ),
            .init(systemImage: "sun.max", title: "明るい所で撮る", detail: "影や光の反射が文字に掛からないようにします。"),
            .init(
                systemImage: "viewfinder",
                title: "1 枚ずつ端まで",
                detail: "上から下まで枠に収めます。長いレシートは、縦に何枚かに分けて撮れます。"
            )
        ],
        buttonTitle: "撮る"
    )
}

private extension EntryGuideCard {
    static let maxWidth: CGFloat = 340
    static let markSize: CGFloat = 32

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

#Preview("品目") {
    EntryGuideCard(guide: .items) {}
        .background(Palette.background)
}

#Preview("撮り方") {
    EntryGuideCard(onConfirm: {}, guide: .receipt) {}
        .background(Palette.background)
}
