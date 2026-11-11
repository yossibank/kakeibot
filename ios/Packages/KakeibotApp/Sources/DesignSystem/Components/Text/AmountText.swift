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
            ? Self.compactText(amount, type: type, sign: sign)
            : Self.text(amount, type: type, sign: sign)

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

    enum Sign {
        case auto
        case plus
    }

    nonisolated static func text(
        _ amount: Int,
        type: Entry.Kind? = nil,
        sign: Sign = .auto
    ) -> String {
        let number = abs(amount).formatted(.number.locale(locale))
        return "\(mark(of: amount, type: type, sign: sign))¥\(number)"
    }

    nonisolated static func compactText(
        _ amount: Int,
        type: Entry.Kind? = nil,
        sign: Sign = .auto
    ) -> String {
        guard abs(amount) >= compactFloor else {
            return text(amount, type: type, sign: sign)
        }

        let number = (abs(amount) / 10000).formatted(.number.locale(locale))
        return "\(mark(of: amount, type: type, sign: sign))\(number)万円"
    }
}

private extension AmountText {
    nonisolated static let locale = Locale(identifier: "ja_JP")
    nonisolated static let compactFloor = 1_000_000

    var typeColor: Color? {
        switch type {
        case .income: Palette.accent
        case .transfer: Palette.subtext
        case .expense: Palette.accentStrong
        case nil: nil
        }
    }

    nonisolated static func mark(
        of amount: Int,
        type: Entry.Kind?,
        sign: Sign
    ) -> String {
        if amount < 0 {
            "−"
        } else if type == .income || (sign == .plus && amount > 0) {
            "+"
        } else {
            ""
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
