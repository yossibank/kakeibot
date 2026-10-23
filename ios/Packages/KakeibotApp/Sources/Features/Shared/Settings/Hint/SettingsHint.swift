import DesignSystem
import SwiftUI

struct SettingsHint: View {
    @Environment(\.themeStyle.corner) private var corner

    private let flag: SettingsScreenFlag
    private let lines: [Line]

    init(
        flag: SettingsScreenFlag,
        lines: [Line]
    ) {
        self.flag = flag
        self.lines = lines
    }

    var body: some View {
        VStack(spacing: 0) {
            if !flag.isOn {
                card
                    .transition(Self.transition)
            }
        }
        .task {
            await flag.load()
        }
    }
}

extension SettingsHint {
    struct Line: Identifiable {
        let systemImage: String
        let text: String

        var id: String {
            text
        }

        init(
            _ systemImage: String,
            _ text: String
        ) {
            self.systemImage = systemImage
            self.text = text
        }
    }
}

extension SettingsHint.Line {
    static let move = Self("hand.draw", "長押しで並べ替えられます")
    static let hide = Self("eye.slash", "下の枠に置くと非表示にできます")
    static let swipeHide = Self("hand.point.left", "横に払っても非表示にできます")
    static let swipeDelete = Self(
        "hand.point.left",
        "横に払うと、非表示と削除のボタンが出ます"
    )
}

private extension SettingsHint {
    static var transition: AnyTransition {
        .opacity.combined(with: .scale(scale: 0.96, anchor: .top))
    }

    static var fill: LinearGradient {
        LinearGradient(
            colors: [Palette.cardTop, Palette.cardBottom],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: corner.radius(16))
    }

    var card: some View {
        HStack(alignment: .top, spacing: 8) {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(lines) { line in
                    row(line)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Button {
                withAnimation(.snappy) {
                    flag.set(true)
                }
            } label: {
                Image(systemName: "xmark")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(Palette.subtext)
                    .frame(width: 24, height: 24)
                    .background(Palette.line, in: Circle())
                    .frame(width: 32, height: 32)
                    .contentShape(.rect)
            }
            .buttonStyle(.plain)
        }
        .padding(.leading, 12)
        .padding(.trailing, 6)
        .padding(.vertical, 10)
        .background(Self.fill, in: shape)
        .overlay {
            shape
                .stroke(Palette.accent.opacity(.soft), lineWidth: 1)
        }
    }

    func row(_ line: Line) -> some View {
        HStack(spacing: 10) {
            Image(systemName: line.systemImage)
                .font(.caption.weight(.medium))
                .foregroundStyle(Palette.accent)
                .frame(width: 26, height: 26)
                .background(Palette.accent.opacity(.subtle), in: Circle())

            Text(line.text)
                .textFont(.footnote)
                .foregroundStyle(Palette.text)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
    }
}
