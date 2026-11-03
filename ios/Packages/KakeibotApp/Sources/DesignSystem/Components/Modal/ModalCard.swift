import SwiftUI

public struct ModalCard<Content: View>: View {
    @Environment(\.themeStyle.corner) private var corner

    @State private var isShown = false

    private let maxWidth: CGFloat
    private let onDismiss: () -> Void
    private let content: Content

    public init(
        maxWidth: CGFloat = 300,
        onDismiss: @escaping () -> Void,
        @ViewBuilder content: () -> Content
    ) {
        self.maxWidth = maxWidth
        self.onDismiss = onDismiss
        self.content = content()
    }

    public var body: some View {
        let scale: CGFloat = isShown ? 1 : 0.94

        return ZStack {
            Palette.scrim
                .opacity(0.55)
                .ignoresSafeArea()
                .onTapGesture(perform: onDismiss)

            content
                .padding(24)
                .frame(maxWidth: maxWidth)
                .background(Palette.panel, in: .rect(cornerRadius: corner.radius(28)))
                .overlay {
                    RoundedRectangle(cornerRadius: corner.radius(28))
                        .stroke(Palette.accent.opacity(.medium), lineWidth: 0.8)
                }
                .shadow(color: Palette.shadow.opacity(0.5), radius: 30, y: 14)
                .padding(.horizontal, 16)
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

#Preview {
    ModalCard(onDismiss: {}) {
        Text("中身")
            .textFont(.subheadline)
            .foregroundStyle(Palette.text)
    }
    .background(Palette.background)
}
