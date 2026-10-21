import DesignSystem
import SwiftUI

struct SettingsHideTarget: View {
    @Binding var zones: SettingsDropZones

    @Environment(\.themeStyle.corner) private var corner

    let isArmed: Bool

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: systemImage)

            Text(title)
        }
        .textFont(.subheadline)
        .foregroundStyle(color)
        .contentTransition(.opacity)
        .frame(maxWidth: .infinity, minHeight: 50)
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
        .animation(.snappy(duration: 0.2), value: isArmed)
        .onGeometryChange(for: CGRect.self) { proxy in
            proxy.frame(in: .global)
        } action: { frame in
            zones.hide = frame
        }
        .transition(.opacity)
        .sensoryFeedback(
            .impact(weight: .heavy),
            trigger: isArmed
        ) { _, new in
            new
        }
    }
}

private extension SettingsHideTarget {
    var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: corner.radius(16))
    }

    var color: Color {
        isArmed ? Palette.rose : Palette.subtext
    }

    var fill: Color {
        isArmed ? color.opacity(.subtle) : .clear
    }

    var systemImage: String {
        isArmed ? "eye.slash.fill" : "eye.slash"
    }

    var title: String {
        isArmed ? "離すと非表示になります" : "ここに置くと非表示にできます"
    }
}
