import Core
import DesignSystem
import FeatureModels
import SwiftUI

struct ReviewEmphasisText: View {
    @Environment(\.themeStyle) private var themeStyle
    @Environment(\.sharedTextScale) private var shared

    let parts: [ReviewEmphasisPart]
    let face: Face
    let weight: Font.Weight?
    let numberFace: Face
    let color: Color

    var body: some View {
        Text(attributed)
            .monospacedDigit()
    }
}

extension ReviewEmphasisText {
    enum Face {
        case text(Font.TextStyle)
        case display(FontSize)
    }
}

extension ReviewEmphasisText {
    static func parts(of why: ReviewCompare.Why) -> [ReviewEmphasisPart] {
        why.parts.map { part in
            switch part {
            case let .text(text): .plain(text)
            case let .number(text): .number(text)
            }
        }
    }
}

private extension ReviewEmphasisText {
    var attributed: AttributedString {
        parts.reduce(into: AttributedString()) { result, part in
            result += run(part)
        }
    }

    func run(_ part: ReviewEmphasisPart) -> AttributedString {
        let style: (text: String, font: Font, color: Color) = switch part {
        case let .plain(text): (text, font(face, weight: weight), color)
        case let .name(text): (text, font(face, weight: weight), Palette.accent)
        case let .number(text): (text, font(numberFace, weight: .bold), Palette.accent)
        }

        var run = AttributedString(style.text)

        run.font = style.font
        run.foregroundColor = style.color

        return run
    }

    func font(
        _ face: Face,
        weight: Font.Weight?
    ) -> Font {
        let scale = themeStyle.textSize.scale

        switch face {
        case let .text(style):
            return .text(
                style,
                weight: weight,
                in: themeStyle.textFont,
                scale: scale,
                shared: shared
            )

        case let .display(size):
            return .display(
                size,
                weight: weight ?? .regular,
                in: themeStyle.displayFont,
                scale: scale,
                shared: shared
            )
        }
    }
}
