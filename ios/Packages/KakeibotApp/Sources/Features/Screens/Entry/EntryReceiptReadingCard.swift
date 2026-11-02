import DesignSystem
import SwiftUI

struct EntryReceiptReadingCard: View {
    var body: some View {
        ZStack {
            Palette.scrim
                .opacity(0.55)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                EntryReceiptArt(kind: .reading)

                EntryReceiptRule(style: .dashed)

                VStack(spacing: 4) {
                    SheetTitle("レシートを読んでいます")

                    Text("品目・合計・日付・店名を探しています")
                        .textFont(.caption)
                        .foregroundStyle(Palette.subtext)
                }
            }
            .padding(28)
            .frame(width: Self.width)
            .background {
                EntryReceiptShape(tooth: 12, hasTopEdge: true)
                    .fill(Palette.card)
                    .shadow(color: Palette.shadow.opacity(0.5), radius: 30, y: 14)
            }
        }
        .transition(.opacity)
    }
}

private extension EntryReceiptReadingCard {
    static let width: CGFloat = 300
}

#Preview {
    EntryReceiptReadingCard()
        .background(Palette.background)
}
