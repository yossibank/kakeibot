import SwiftUI

public struct MenuPanel<Content: View>: View {
    let width: CGFloat
    let content: Content

    public init(
        width: CGFloat,
        @ViewBuilder content: () -> Content
    ) {
        self.width = width
        self.content = content()
    }

    public var body: some View {
        VStack(spacing: 0) {
            content
        }
        .frame(width: width)
        .background(Palette.drawer, in: .rect(cornerRadius: 18))
        .overlay {
            RoundedRectangle(cornerRadius: 18)
                .stroke(Palette.gold.opacity(.medium), lineWidth: 0.8)
        }
        .shadow(color: .black.opacity(0.5), radius: 24, y: 12)
    }
}

#Preview {
    MenuPanel(width: 236) {
        MenuRow(
            "並べた順",
            systemImage: "line.3.horizontal",
            isSelected: true
        ) {}

        MenuDivider()

        MenuRow("名前順", systemImage: "textformat") {}
    }
    .padding()
    .background(Palette.night)
}
