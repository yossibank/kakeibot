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

        VStack(spacing: 4) {
            Text("\(date.month)月")
                .textFont(.caption2)
                .tracking(1)
                .foregroundStyle(Palette.accent)

            Capsule()
                .fill(Palette.accent.opacity(.medium))
                .frame(width: 20, height: 1)

            Text("\(date.day)")
                .displayFont(.title)
                .monospacedDigit()
                .foregroundStyle(Palette.text)

            Text(date.weekday.shortName)
                .textFont(.caption2)
                .foregroundStyle(date.tint ?? Palette.subtext)
        }
        .padding(.top, 12)
        .padding(.bottom, 8)
        .frame(width: 52)
        .background(Palette.panel, in: shape)
        .overlay {
            shape
                .stroke(ring, lineWidth: width)
        }
        .overlay(alignment: .top) {
            HStack(spacing: 20) {
                binding
                binding
            }
            .offset(y: -4)
        }
        .padding(.top, 4)
    }
}

private extension FlipDate {
    var binding: some View {
        Capsule()
            .fill(Palette.accent)
            .frame(width: 3, height: 9)
            .overlay {
                Capsule()
                    .stroke(
                        Palette.backgroundBottom.opacity(0.5),
                        lineWidth: 0.5
                    )
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
