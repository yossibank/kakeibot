import DesignSystem
import SwiftUI

struct EntryDialFace: View {
    let model: EntryModel
    let isActive: Bool
    let size: CGFloat

    var body: some View {
        ZStack {
            DialFace(isActive: isActive)

            Text(model.typeName)
                .font(.serif(.caption))
                .tracking(5)
                .foregroundStyle(Palette.accent)
                .offset(y: -size * 0.19)

            Text(AmountText.text(model.amount))
                .font(amountFont)
                .monospacedDigit()
                .foregroundStyle(Palette.accentLight)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
                .frame(width: size * 0.7, height: size * 0.26)

            Text(note)
                .font(.caption2)
                .foregroundStyle(Palette.subtext)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .frame(width: size * 0.66)
                .offset(y: size * 0.19)
        }
        .frame(width: size, height: size)
        .contentShape(Circle())
    }
}

private extension EntryDialFace {
    var amountFont: Font {
        let scale: CGFloat = model.amount < 100_000 ? 0.2 : 0.118
        return .system(size: size * scale, weight: .semibold, design: .serif)
    }

    var note: String {
        model.expressionText ?? (isActive ? "入力中" : "タップして入力")
    }
}
