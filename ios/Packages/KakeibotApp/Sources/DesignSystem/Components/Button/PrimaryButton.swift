import SwiftUI

public struct PrimaryButton: View {
    @Environment(\.isEnabled) private var isEnabled

    let title: String
    let action: () -> Void

    public init(
        _ title: String,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Text(title)
                .font(.body.weight(.bold))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .foregroundStyle(textColor)
                .frame(maxWidth: .infinity, minHeight: 56)
                .background {
                    face
                }
                .overlay {
                    Capsule()
                        .strokeBorder(rim, lineWidth: 1)
                }
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .shadow(color: glow, radius: 14, y: 6)
    }
}

private extension PrimaryButton {
    @ViewBuilder
    var face: some View {
        if isEnabled {
            Capsule()
                .fill(Self.gold)
                .overlay {
                    Capsule()
                        .fill(Self.sheen)
                }
        } else {
            Capsule()
                .fill(Palette.card)
        }
    }
}

private extension PrimaryButton {
    static var gold: LinearGradient {
        LinearGradient(
            colors: [
                Palette.gold.mix(with: Palette.champagne, by: 0.3),
                Palette.gold,
                Palette.gold.mix(with: Palette.bronze, by: 0.45)
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

    var textColor: Color {
        isEnabled ? Palette.nightBottom : Palette.mist
    }

    var rim: LinearGradient {
        let colors = if isEnabled {
            [Palette.champagne.opacity(.strong), Palette.gold.opacity(.soft)]
        } else {
            [Palette.gold.opacity(.muted), Palette.gold.opacity(.subtle)]
        }

        return LinearGradient(
            colors: colors,
            startPoint: .top,
            endPoint: .bottom
        )
    }

    var glow: Color {
        isEnabled ? Palette.gold.opacity(.muted) : .clear
    }
}

#Preview {
    VStack(spacing: 16) {
        PrimaryButton("¥12,800 を記録する") {}

        PrimaryButton("金額を入れてください") {}
            .disabled(true)
    }
    .padding()
    .background(Palette.night)
}
