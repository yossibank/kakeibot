import SwiftUI

public extension View {
    func card(cornerRadius: CGFloat = 22) -> some View {
        modifier(CardBackground(cornerRadius: cornerRadius))
    }
}

private struct CardBackground: ViewModifier {
    let cornerRadius: CGFloat

    func body(content: Content) -> some View {
        content
            .background(Palette.card, in: .rect(cornerRadius: cornerRadius))
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(Palette.gold.opacity(0.28), lineWidth: 1)
            }
    }
}

#Preview {
    VStack(spacing: 16) {
        Text("今月の支出")
            .foregroundStyle(Palette.ink)
            .frame(maxWidth: .infinity, minHeight: 120)
            .card(cornerRadius: 24)

        Text("最近の記録")
            .foregroundStyle(Palette.ink)
            .frame(maxWidth: .infinity, minHeight: 80)
            .card()
    }
    .padding()
    .background(Palette.night)
}
