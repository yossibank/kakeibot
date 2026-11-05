import Core
import SwiftUI

public struct FlipDate: View {
    @Environment(\.themeStyle.corner) private var corner

    let date: LocalDate
    let isSelected: Bool
    let isCompact: Bool

    public init(
        _ date: LocalDate,
        isSelected: Bool = false,
        isCompact: Bool = false
    ) {
        self.date = date
        self.isSelected = isSelected
        self.isCompact = isCompact
    }

    public var body: some View {
        let shape = RoundedRectangle(cornerRadius: corner.radius(12))
        let ring = isSelected ? Palette.accent : Palette.outline
        let width: CGFloat = isSelected ? 1.5 : 1

        VStack(spacing: isCompact ? 2 : 4) {
            Text("\(date.month)月")
                .textFont(.caption2)
                .tracking(1)
                .foregroundStyle(Palette.accent)

            Capsule()
                .fill(Palette.accent.opacity(.medium))
                .frame(width: 20, height: 1)

            Text("\(date.day)")
                .displayFont(isCompact ? .headline : .title)
                .monospacedDigit()
                .foregroundStyle(Palette.text)

            Text(date.weekday.shortName)
                .textFont(.caption2)
                .foregroundStyle(date.tint ?? Palette.subtext)
        }
        .padding(.top, isCompact ? 8 : 12)
        .padding(.bottom, isCompact ? 4 : 8)
        .frame(width: isCompact ? 44 : 52)
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
                    .stroke(Palette.backgroundBottom.opacity(0.5), lineWidth: 0.5)
            }
    }
}

#Preview {
    HStack(spacing: 12) {
        if let date = LocalDate("2026-10-27") {
            FlipDate(date)

            FlipDate(date, isSelected: true)

            FlipDate(date, isCompact: true)
        }
    }
    .padding()
    .background(Palette.background)
}
