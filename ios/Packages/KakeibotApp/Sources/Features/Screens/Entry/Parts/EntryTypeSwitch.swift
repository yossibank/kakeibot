import Core
import DesignSystem
import SwiftUI

struct EntryTypeSwitch: View {
    @Binding var selection: Entry.Kind

    @State private var tapCount = 0

    @Environment(\.themeStyle.corner) private var corner

    @Namespace private var face

    var body: some View {
        HStack(spacing: 8) {
            ForEach(Self.kinds, id: \.self) { kind in
                key(kind)
            }
        }
        .animation(.spring(duration: 0.35, bounce: 0.25), value: tapCount)
    }
}

private extension EntryTypeSwitch {
    static let faceID = "face"

    static var kinds: [Entry.Kind] {
        [.expense, .income, .transfer]
    }

    static var gold: LinearGradient {
        LinearGradient(
            colors: [Palette.accentStrong, Palette.accent, Palette.accentDeep],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var keyFill: LinearGradient {
        LinearGradient(
            colors: [
                Palette.cardTop.mix(with: .white, by: 0.12),
                Palette.cardTop,
                Palette.cardTop.mix(with: .black, by: 0.1)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    static var shine: LinearGradient {
        LinearGradient(
            stops: [
                .init(color: .white.opacity(0.4), location: 0),
                .init(color: .clear, location: 0.4)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    func key(_ kind: Entry.Kind) -> some View {
        let isSelected = selection == kind
        let shape = RoundedRectangle(cornerRadius: corner.radius(12))
        let color = isSelected ? Palette.backgroundBottom : Palette.subtext
        let weight: Font.Weight = isSelected ? .bold : .medium
        let press: CGFloat = isSelected ? 2 : 0

        return Button {
            selection = kind
            tapCount += 1
        } label: {
            HStack(spacing: 4) {
                Image(systemName: symbol(of: kind))
                    .textFont(.caption2, weight: weight)
                    .keyframeAnimator(initialValue: 1.0, trigger: tapCount) { content, scale in
                        content
                            .scaleEffect(isSelected ? scale : 1)
                    } keyframes: { _ in
                        SpringKeyframe(1.4, duration: 0.15)
                        SpringKeyframe(1, duration: 0.3, spring: .bouncy)
                    }

                Text(title(of: kind))
                    .textFont(.subheadline, weight: weight)
                    .fixedSize()
            }
            .foregroundStyle(color)
            .padding(.horizontal, 4)
            .frame(maxWidth: 76)
            .frame(height: 34)
            .background {
                face(isSelected: isSelected, shape: shape)
            }
            .contentShape(shape)
            .offset(y: press)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    func face(
        isSelected: Bool,
        shape: RoundedRectangle
    ) -> some View {
        if isSelected {
            shape
                .fill(Self.gold)
                .overlay {
                    shape
                        .inset(by: 1)
                        .stroke(Self.shine, lineWidth: 1)
                }
                .glow(Palette.glow.opacity(.muted), radius: 8)
                .matchedGeometryEffect(id: Self.faceID, in: face)
        } else {
            shape
                .fill(Self.keyFill)
                .background {
                    shape
                        .fill(Palette.cardTop.mix(with: .black, by: 0.35))
                        .offset(y: 2)
                        .shadow(color: Palette.shadow.opacity(.soft), radius: 3, y: 2)
                }
                .overlay {
                    shape
                        .strokeBorder(Palette.accent.opacity(.muted), lineWidth: 1)
                }
        }
    }

    func title(of kind: Entry.Kind) -> String {
        switch kind {
        case .expense: "支出"
        case .income: "収入"
        case .transfer: "振替"
        }
    }

    func symbol(of kind: Entry.Kind) -> String {
        switch kind {
        case .expense: "arrow.up"
        case .income: "arrow.down"
        case .transfer: "arrow.left.arrow.right"
        }
    }
}
