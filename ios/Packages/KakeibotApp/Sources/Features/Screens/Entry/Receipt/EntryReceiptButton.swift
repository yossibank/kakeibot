import DesignSystem
import SwiftUI

struct EntryReceiptButton: View {
    let freeLeft: Int?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: "doc.text.viewfinder")
                    .foregroundStyle(Palette.accent)

                Text("レシート")
                    .foregroundStyle(Palette.accentStrong)

                if let freeLeft {
                    Text("あと\(freeLeft)回")
                        .textFont(.caption2)
                        .monospacedDigit()
                        .foregroundStyle(freeLeft == 0 ? Palette.amber : Palette.subtext)
                }
            }
            .textFont(.caption, weight: .semibold)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .padding(.horizontal, 12)
            .padding(.bottom, Self.tooth / 2)
            .frame(height: Self.height)
            .background {
                paper
                    .fill(Palette.card)
                    .shadow(color: Palette.shadow.opacity(0.5), radius: 3, y: 1)
            }
            .overlay {
                paper
                    .stroke(Palette.outline, lineWidth: 1)
            }
            .contentShape(.rect)
            .tapArea(Self.tapOutsets)
        }
        .buttonStyle(.plain)
    }
}

private extension EntryReceiptButton {
    static let height: CGFloat = 34
    static let tooth: CGFloat = 6

    static let tapOutsets = EdgeInsets(
        top: 5,
        leading: 0,
        bottom: 5,
        trailing: 0
    )

    var paper: EntryReceiptShape {
        EntryReceiptShape(tooth: Self.tooth, hasTopEdge: false)
    }
}

#Preview {
    VStack(spacing: 16) {
        EntryReceiptButton(freeLeft: 2) {}

        EntryReceiptButton(freeLeft: 0) {}

        EntryReceiptButton(freeLeft: nil) {}
    }
    .padding()
    .background(Palette.panel)
}
