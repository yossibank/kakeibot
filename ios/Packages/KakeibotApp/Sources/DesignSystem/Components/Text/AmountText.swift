import Core
import SwiftUI

public struct AmountText: View {
    let amount: Int
    let type: Entry.Kind?
    let font: FontSpec
    let sign: Sign
    let color: Color?
    let isCompact: Bool

    public init(
        _ amount: Int,
        type: Entry.Kind? = nil,
        font: FontSpec,
        sign: Sign = .auto,
        color: Color? = nil,
        isCompact: Bool = false
    ) {
        self.amount = amount
        self.type = type
        self.font = font
        self.sign = sign
        self.color = color
        self.isCompact = isCompact
    }

    public var body: some View {
        let text = isCompact
            ? Yen.compactText(amount, type: type, sign: sign)
            : Yen.text(amount, type: type, sign: sign)

        Text(text)
            .modifier(AmountFont(spec: font))
            .monospacedDigit()
            .modifier(AmountTint(color: color ?? typeColor))
    }
}

public extension AmountText {
    enum FontSpec {
        case size(FontSize, weight: Font.Weight = .regular)
        case style(Font.TextStyle, weight: Font.Weight? = nil)
        case fixed(Font)
    }

    typealias Sign = Yen.Sign
}

private extension AmountText {
    var typeColor: Color? {
        switch type {
        case .income: Palette.accent
        case .transfer: Palette.subtext
        case .expense: Palette.accentStrong
        case nil: nil
        }
    }
}

private struct AmountFont: ViewModifier {
    let spec: AmountText.FontSpec

    func body(content: Content) -> some View {
        switch spec {
        case let .size(size, weight):
            content.displayFont(size, weight: weight)

        case let .style(style, weight):
            content.displayFont(style: style, weight: weight)

        case let .fixed(font):
            content.font(font)
        }
    }
}

private struct AmountTint: ViewModifier {
    let color: Color?

    func body(content: Content) -> some View {
        if let color {
            content.foregroundStyle(color)
        } else {
            content
        }
    }
}

#Preview {
    VStack(alignment: .trailing) {
        AmountText(980, type: .expense, font: .size(.body))
        AmountText(250_000, type: .income, font: .size(.body))
        AmountText(3000, type: .transfer, font: .size(.body))
        AmountText(1_234_567, font: .style(.subheadline, weight: .semibold))
        AmountText(-24800, font: .style(.subheadline))
        AmountText(1200, font: .style(.footnote), sign: .plus, color: Palette.accent)
    }
    .padding()
    .background(Palette.background)
}
