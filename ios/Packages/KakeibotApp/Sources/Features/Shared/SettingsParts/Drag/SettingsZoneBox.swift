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
        let isClosed = layout.phase == .closed
        let height = isClosed ? closedHeight : SettingsDropZones.openHeight
        let labelHeight = isClosed ? closedHeight : SettingsDropZones.labelHeight
        let label = layout.phase == .open ? onLabel : offLabel

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
        var phase: OpenPhase = .closed
    }

    enum OpenPhase {
        case closed
        case opening
        case open
    }
}

private extension SettingsZoneBox {
    var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: corner.radius(16))
    }

    func update() {
        guard isOn else {
            layout.phase = layout.phase == .closed ? .closed : .opening

            withAnimation(.smooth(duration: 0.3)) {
                layout.phase = .closed
            }

            return
        }

        withAnimation(.spring(duration: 0.4, bounce: 0.35)) {
            layout.phase = .opening
        } completion: {
            if isOn {
                layout.phase = .open
            }
        }
    }
}
