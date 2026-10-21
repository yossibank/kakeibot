import DesignSystem
import SwiftUI

struct SettingsHideZone: View {
    @Environment(\.themeStyle.corner) private var corner

    let state: SettingsHideHover.State
    let height: CGFloat

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: systemImage)

            Text(title)
        }
        .textFont(.subheadline)
        .foregroundStyle(color)
        .contentTransition(.opacity)
        .frame(maxWidth: .infinity, minHeight: height)
        .background {
            shape
                .fill(Palette.backgroundBottom.opacity(.strong))

            shape
                .fill(fill)
        }
        .overlay {
            shape
                .stroke(color.opacity(0.6), style: .dashed)
        }
        .animation(.snappy(duration: 0.2), value: state)
    }
}

private extension SettingsHideZone {
    var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: corner.radius(16))
    }

    var color: Color {
        switch state {
        case .outside: Palette.subtext
        case .armed: Palette.rose
        }
    }

    var fill: Color {
        state == .armed ? color.opacity(.subtle) : .clear
    }

    var systemImage: String {
        state == .armed ? "eye.slash.fill" : "eye.slash"
    }

    var title: String {
        switch state {
        case .outside: "ここに置くと非表示にできます"
        case .armed: "離すと非表示になります"
        }
    }
}
