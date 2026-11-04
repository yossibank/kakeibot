import Core
import SwiftUI

public struct FlipDate: View {
    @Environment(\.themeStyle.corner) private var corner

    let date: LocalDate
    let isSelected: Bool
    let size: Size

    public init(
        _ date: LocalDate,
        isSelected: Bool = false,
        size: Size = .regular
    ) {
        self.date = date
        self.isSelected = isSelected
        self.size = size
    }

    public var body: some View {
        switch size {
        case .regular: regular
        case .small: small
        }
    }
}

public extension FlipDate {
    enum Size: Hashable, Sendable {
        case regular
        case small
    }
}

private extension FlipDate {
    var small: some View {
        let shape = RoundedRectangle(cornerRadius: corner.radius(8))

        return Text("\(date.day)")
            .displayFont(.headline)
            .monospacedDigit()
            .foregroundStyle(Palette.text)
            .padding(.top, 4)
            .frame(width: 36, height: 36)
            .background(Palette.panel, in: shape)
            .overlay {
                shape
                    .stroke(Palette.outline, lineWidth: 1)
            }
            .overlay(alignment: .top) {
                HStack(spacing: 12) {
                    binding
                    binding
                }
                .offset(y: -4)
            }
            .padding(.top, 4)
    }

    @ViewBuilder
    var regular: some View {
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
        }
    }
    .padding()
    .background(Palette.background)
}
