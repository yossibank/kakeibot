import Core
import DesignSystem
import SwiftUI

struct SettingsZoneBox: View {
    @State private var layout = Layout()

    @Environment(\.themeStyle.corner) private var corner

    let isOn: Bool
    let closedHeight: CGFloat
    let tint: Color
    let offLabel: Caption
    let onLabel: Caption

    var body: some View {
        let color = isOn ? tint : Palette.subtext
        let fill = isOn ? tint.opacity(.subtle) : Color.clear
        let opening = layout.opening
        let height = closedHeight + (SettingsDropZones.openHeight - closedHeight) * opening
        let labelHeight = closedHeight + (SettingsDropZones.labelHeight - closedHeight) * opening
        let label = layout.onLabel > 0 ? onLabel : offLabel

        VStack(spacing: 0) {
            ZStack {
                HStack(spacing: 8) {
                    Image(systemName: label.systemImage)

                    Text(label.title)
                }
                .foregroundStyle(color)
                .id(isOn)
                .transition(.opacity)
            }
            .frame(maxWidth: .infinity, minHeight: labelHeight)

            Spacer(minLength: 0)
        }
        .textFont(.subheadline)
        .frame(height: height, alignment: .top)
        .clipShape(shape)
        .background {
            SettingsZoneFrame(color: color, fill: fill)
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
    struct Layout {
        var opening: Double = 0
        var onLabel: Double = 0
    }

    var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: corner.radius(16))
    }
}

private extension SettingsZoneBox {
    func update() {
        guard isOn else {
            layout.onLabel = 0

            withAnimation(.smooth(duration: 0.3)) {
                layout.opening = 0
            }

            return
        }

        withAnimation(.spring(duration: 0.4, bounce: 0.35)) {
            layout.opening = 1
        } completion: {
            layout.onLabel = isOn ? 1 : 0
        }
    }
}
