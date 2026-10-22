import Core
import SwiftUI

public struct BuddyBubble: View {
    @Environment(\.themeStyle.corner) private var corner

    let buddy: Buddy
    let name: String
    let line: BuddyLine

    public init(
        _ buddy: Buddy,
        name: String,
        line: BuddyLine
    ) {
        self.buddy = buddy
        self.name = name
        self.line = line
    }

    public var body: some View {
        HStack(alignment: .center, spacing: 10) {
            BuddyFace(buddy, mood: line.mood, size: 52)

            VStack(alignment: .leading, spacing: 3) {
                Text(name)
                    .textFont(.caption2, weight: .semibold)
                    .tracking(1)
                    .foregroundStyle(Palette.accent)

                Text(line.text)
                    .textFont(.footnote)
                    .foregroundStyle(Palette.text)
                    .fixedSize(horizontal: false, vertical: true)
                    .contentTransition(.opacity)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Palette.card, in: shape)
            .overlay {
                shape
                    .stroke(rim, lineWidth: 1)
            }
            .overlay(alignment: .leading) {
                BubbleTail()
                    .fill(Palette.cardTop)
                    .overlay {
                        BubbleTail()
                            .stroke(rim, lineWidth: 1)
                    }
                    .frame(width: 8, height: 12)
                    .offset(x: -7)
            }
        }
        .animation(.snappy, value: line)
    }
}

private extension BuddyBubble {
    var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: corner.radius(16))
    }

    var rim: Color {
        Palette.accent.opacity(.muted)
    }
}

private struct BubbleTail: Shape {
    func path(in rect: CGRect) -> Path {
        Path { path in
            path.move(to: CGPoint(x: rect.maxX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.midY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        BuddyBubble(
            .cat,
            name: "たま",
            line: .budget(nil)
        )

        BuddyBubble(
            .bear,
            name: "くま",
            line: .reward(count: 2)
        )
    }
    .padding()
    .background(Palette.background)
}
