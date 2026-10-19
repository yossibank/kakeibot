import DesignSystem
import SwiftUI

struct SettingsHideZone: View {
    @State private var progress: CGFloat = 0

    let state: SettingsHideHover.State
    let height: CGFloat

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: systemImage)

            Text(title)
        }
        .font(.subheadline)
        .foregroundStyle(color)
        .contentTransition(.opacity)
        .frame(maxWidth: .infinity, minHeight: height)
        .background {
            Self.shape
                .fill(Palette.backgroundBottom.opacity(.strong))

            GeometryReader { proxy in
                Rectangle()
                    .fill(color.opacity(.subtle))
                    .frame(width: proxy.size.width * progress)
            }
            .clipShape(Self.shape)
        }
        .overlay {
            Self.shape
                .stroke(color.opacity(0.6), style: .dashed)
        }
        .onChange(of: state, initial: true) {
            fill()
        }
    }
}

private extension SettingsHideZone {
    static let shape = RoundedRectangle(cornerRadius: 16)

    var color: Color {
        switch state {
        case .outside: Palette.subtext
        case .waiting: Palette.amber
        case .armed: Palette.rose
        }
    }

    var systemImage: String {
        state == .armed ? "eye.slash.fill" : "eye.slash"
    }

    var title: String {
        switch state {
        case .outside: "ここで少し待つと非表示にできます"
        case .waiting: "そのまま待ってください"
        case .armed: "離すと非表示になります"
        }
    }

    func fill() {
        switch state {
        case .outside:
            progress = 0
        case .waiting:
            progress = 0

            withAnimation(.linear(duration: SettingsHideHover.delay)) {
                progress = 1
            }
        case .armed:
            progress = 1
        }
    }
}
