import Core
import DesignSystem
import SwiftUI

struct HomeSectionThumbnail: View {
    @Environment(\.themeStyle.corner) private var corner

    let section: HomeSection

    var body: some View {
        content
            .frame(width: Self.size.width, height: Self.size.height)
            .background(Palette.card, in: .rect(cornerRadius: corner.radius(8)))
            .overlay {
                RoundedRectangle(cornerRadius: corner.radius(8))
                    .stroke(Palette.outline, lineWidth: 0.8)
            }
    }
}

private extension HomeSectionThumbnail {
    @ViewBuilder
    var content: some View {
        switch section {
        case .customize: customize
        case .budget: budget
        case .templates: templates
        case .recent: recent
        case .bills: bills
        case .stamps: stamps
        }
    }

    var customize: some View {
        HStack(spacing: 3) {
            ForEach(0..<3, id: \.self) { _ in
                RoundedRectangle(cornerRadius: 2)
                    .stroke(Palette.accent.opacity(.muted), lineWidth: 1)
                    .frame(width: 9, height: 12)
            }
        }
    }

    var budget: some View {
        Circle()
            .trim(from: 0.5, to: 1)
            .stroke(Palette.accent.opacity(.muted), style: Self.dialStroke)
            .frame(width: 26, height: 26)
            .offset(y: 6)
    }

    var templates: some View {
        Grid(horizontalSpacing: 3, verticalSpacing: 3) {
            ForEach(0..<2, id: \.self) { _ in
                GridRow {
                    ForEach(0..<2, id: \.self) { _ in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Palette.accent.opacity(.muted))
                            .frame(width: 12, height: 7)
                    }
                }
            }
        }
    }

    var recent: some View {
        VStack(spacing: 4) {
            ForEach(Self.recentWidths, id: \.self) { width in
                HStack(spacing: 3) {
                    Circle()
                        .fill(Palette.accent.opacity(.subtle))
                        .frame(width: 5, height: 5)

                    line(Palette.text, width: width)
                }
            }
        }
    }

    var bills: some View {
        VStack(spacing: 5) {
            ForEach(Self.billWidths, id: \.self) { width in
                HStack(spacing: 3) {
                    line(Palette.accent, width: 6)

                    line(Palette.text, width: width)
                }
            }
        }
    }

    var stamps: some View {
        HStack(spacing: 4) {
            ForEach(0..<3, id: \.self) { _ in
                Circle()
                    .stroke(Palette.accent.opacity(.muted), lineWidth: 1.5)
                    .frame(width: 8, height: 8)
            }
        }
    }

    func line(
        _ color: Color,
        width: CGFloat
    ) -> some View {
        Capsule()
            .fill(color.opacity(.muted))
            .frame(width: width, height: 3)
    }
}

private extension HomeSectionThumbnail {
    static let size = CGSize(width: 44, height: 32)
    static let dialStroke = StrokeStyle(lineWidth: 3, lineCap: .round)
    static let recentWidths: [CGFloat] = [20, 16, 22]
    static let billWidths: [CGFloat] = [18, 22]
}
