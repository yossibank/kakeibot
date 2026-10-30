import SwiftUI

public struct GoldSwitch<Label: View>: View {
    @Binding var isOn: Bool

    @Environment(\.themeStyle.decorations) private var hasDecorations

    let systemImage: String
    let label: Label

    public init(
        isOn: Binding<Bool>,
        systemImage: String,
        @ViewBuilder label: () -> Label
    ) {
        _isOn = isOn

        self.systemImage = systemImage
        self.label = label()
    }

    public var body: some View {
        Button {
            isOn.toggle()
        } label: {
            HStack(spacing: 12) {
                label
                    .frame(maxWidth: .infinity, alignment: .leading)

                track
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(minHeight: 44)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .animation(.snappy(duration: 0.25), value: isOn)
        .haptic(.impact(weight: .light), trigger: isOn)
    }
}

private extension GoldSwitch {
    var rim: Color {
        isOn ? Palette.accentStrong.opacity(.strong) : Palette.outline
    }

    var track: some View {
        let stateText = isOn ? "入" : "切"
        let textColor = isOn ? Palette.backgroundBottom : Palette.subtext
        let textX = isOn ? Self.inset : Self.knobSize + Self.inset
        let knobX = isOn ? Self.width - Self.knobSize - Self.inset : Self.inset
        let glow = isOn ? Palette.glow.opacity(.muted) : .clear

        return ZStack(alignment: .leading) {
            Text(stateText)
                .textFont(.caption2, weight: .bold)
                .foregroundStyle(textColor)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .frame(width: Self.textWidth)
                .offset(x: textX)

            knob
                .offset(x: knobX)
        }
        .frame(width: Self.width, height: Self.height, alignment: .leading)
        .background {
            face
        }
        .overlay {
            Capsule()
                .strokeBorder(rim, lineWidth: 1)
        }
        .glow(glow, radius: 8, y: 2)
    }

    var knob: some View {
        let fill = isOn ? Palette.backgroundBottom : Palette.panel
        let iconColor = isOn ? Palette.accentStrong : Palette.subtext
        let ring = isOn ? Palette.accentStrong.opacity(.medium) : Palette.outline

        return Circle()
            .fill(fill)
            .overlay {
                Circle()
                    .strokeBorder(ring, lineWidth: 1)
            }
            .overlay {
                Image(systemName: systemImage)
                    .sansFont(.small, weight: .semibold)
                    .foregroundStyle(iconColor)
            }
            .frame(width: Self.knobSize, height: Self.knobSize)
    }

    @ViewBuilder
    var face: some View {
        if isOn {
            Capsule()
                .fill(Self.gold)
                .overlay {
                    if hasDecorations {
                        Capsule()
                            .fill(Self.sheen)
                    }
                }
        } else {
            Capsule()
                .fill(Palette.faint)
        }
    }
}

private extension GoldSwitch {
    static var width: CGFloat {
        64
    }

    static var height: CGFloat {
        34
    }

    static var inset: CGFloat {
        3
    }

    static var knobSize: CGFloat {
        height - inset * 2
    }

    static var textWidth: CGFloat {
        width - knobSize - inset * 2
    }

    static var gold: LinearGradient {
        LinearGradient(
            colors: [
                Palette.accent.mix(with: Palette.accentStrong, by: 0.3),
                Palette.accent,
                Palette.accent.mix(with: Palette.accentDeep, by: 0.45)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    static var sheen: LinearGradient {
        LinearGradient(
            colors: [.white.opacity(0.22), .white.opacity(0)],
            startPoint: .top,
            endPoint: .center
        )
    }
}

#Preview {
    @Previewable @State var haptics = true
    @Previewable @State var decorations = false

    VStack(spacing: 12) {
        GoldSwitch(isOn: $haptics, systemImage: "waveform") {
            Text("押した時の振動")
        }

        GoldSwitch(isOn: $decorations, systemImage: "sparkle") {
            Text("金の光などの飾り")
        }
    }
    .padding()
    .background(Palette.background)
}
