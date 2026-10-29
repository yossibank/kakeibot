import Core
import DesignSystem
import SwiftUI

struct SettingsHint: View {
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
    struct Line {
        let systemImage: String
        let text: String

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
    static let hide = Self("eye.slash", "長押しして下の枠へ運ぶと非表示にできます")
    static let swipeHide = Self("hand.point.left", "横に払っても非表示にできます")
    static let swipeDelete = Self("hand.point.left", "横に払うと、非表示と削除のボタンが出ます")
}

private extension SettingsHint {
    var card: some View {
        HStack(alignment: .top, spacing: 8) {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(lines) { line in
                    row(line)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            RingButton(
                systemImage: "xmark",
                size: .small
            ) {
                withAnimation(.snappy) {
                    _ = flag.set(true)
                }
            }
        }
        .padding(.leading, 12)
        .padding(.trailing, 8)
        .padding(.vertical, 12)
        .settingsTileFace(isHidden: false)
    }

    func row(_ line: Line) -> some View {
        HStack(spacing: 12) {
            Image(systemName: line.systemImage)
                .sansFont(.caption, weight: .medium)
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

private extension SettingsHint {
    static var transition: AnyTransition {
        .opacity.combined(with: .scale(scale: 0.96, anchor: .top))
    }
}

extension SettingsHint.Line: Identifiable {
    var id: String {
        text
    }
}
