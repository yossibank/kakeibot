import DesignSystem
import SwiftUI

struct SettingsZoneBox: View {
    @State private var isOpen = false
    @State private var showsOnLabel = false

    @Environment(\.themeStyle.corner) private var corner

    let isOn: Bool
    let closedHeight: CGFloat
    let tint: Color
    let offLabel: Caption
    let onLabel: Caption

    var body: some View {
        let color = isOn ? tint : Palette.subtext
        let fill = isOn ? tint.opacity(.subtle) : Color.clear
        let height = isOpen ? SettingsDropZones.openHeight : closedHeight
        let labelHeight = isOpen ? SettingsDropZones.labelHeight : closedHeight
        let label = showsOnLabel ? onLabel : offLabel

        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: label.systemImage)

                Text(label.title)
            }
            .frame(maxWidth: .infinity, minHeight: labelHeight)

            Spacer(minLength: 0)
        }
        .textFont(.subheadline)
        .foregroundStyle(color)
        .frame(height: height, alignment: .top)
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
        .animation(.smooth(duration: 0.2), value: isOn)
        .onChange(of: isOn) {
            update()
        }
    }
}

extension SettingsZoneBox {
    struct Caption {
        let systemImage: String
        let title: String
    }
}

private extension SettingsZoneBox {
    var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: corner.radius(16))
    }

    func update() {
        guard isOn else {
            showsOnLabel = false

            withAnimation(.smooth(duration: 0.3)) {
                isOpen = false
            }

            return
        }

        withAnimation(.spring(duration: 0.4, bounce: 0.35)) {
            isOpen = true
        } completion: {
            showsOnLabel = isOn
        }
    }
}
