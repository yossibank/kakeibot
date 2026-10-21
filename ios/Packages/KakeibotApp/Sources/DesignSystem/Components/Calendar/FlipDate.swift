import Core
import SwiftUI

public struct FlipDate: View {
    @Environment(\.themeStyle.corner) private var corner

    let date: LocalDate
    let isSelected: Bool

    public init(
        _ date: LocalDate,
        isSelected: Bool = false
    ) {
        self.date = date
        self.isSelected = isSelected
    }

    public var body: some View {
        let shape = RoundedRectangle(cornerRadius: corner.radius(12))
        let ring = isSelected ? Palette.accent : Palette.outline
        let width: CGFloat = isSelected ? 1.5 : 1

        VStack(spacing: 0) {
            Text("\(date.month)月")
                .textFont(.caption2)
                .foregroundStyle(Palette.backgroundBottom)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 2)
                .background(Palette.accent)

            Text("\(date.day)")
                .displayFont(.title)
                .monospacedDigit()
                .foregroundStyle(Palette.text)
                .padding(.top, 2)

            Text(date.weekday.shortName)
                .textFont(.caption2)
                .foregroundStyle(date.tint ?? Palette.subtext)
                .padding(.bottom, 4)
        }
        .frame(width: 52)
        .background(Palette.panel)
        .clipShape(shape)
        .overlay {
            shape
                .stroke(ring, lineWidth: width)
        }
    }
}

#Preview {
    HStack(spacing: 12) {
        if let date = LocalDate("2026-10-27") {
            FlipDate(date)
            FlipDate(date, isSelected: true)
        }
    }
    .padding()
    .background(Palette.background)
}
