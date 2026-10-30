import Core
import DesignSystem
import SwiftUI

struct HomeSectionThumbnail: View {
    @Environment(\.themeStyle.corner) private var corner

    let section: HomeSection

    var body: some View {
        content
            .padding(6)
            .frame(width: Self.size.width, height: Self.size.height, alignment: .topLeading)
            .background(Palette.card, in: .rect(cornerRadius: corner.radius(8)))
            .overlay {
                RoundedRectangle(cornerRadius: corner.radius(8))
                    .stroke(Palette.outline, lineWidth: 0.8)
            }
            .shadow(color: Palette.shadow.opacity(0.3), radius: 3, y: 1)
    }
}

private extension HomeSectionThumbnail {
    @ViewBuilder
    var content: some View {
        switch section {
        case .customize: titled(customize)
        case .budget: budget
        case .templates: titled(templates)
        case .recent: titled(recent)
        case .bills: titled(bills)
        case .stamps: titled(stamps)
        }
    }

    var customize: some View {
        HStack(spacing: 3) {
            ForEach(Self.dots.prefix(3).indices, id: \.self) { index in
                let isLit = index == 0
                let glowColor = isLit ? Palette.glow : Color.clear
                let strokeColor = isLit ? Palette.accent : Palette.outline

                RoundedRectangle(cornerRadius: 2)
                    .fill(Palette.faint)
                    .overlay {
                        RoundedRectangle(cornerRadius: 2)
                            .stroke(strokeColor, lineWidth: 0.6)
                    }
                    .overlay {
                        Circle()
                            .fill(Self.dots[index])
                            .frame(width: 5, height: 5)
                    }
                    .frame(width: 12, height: 16)
                    .glow(glowColor, radius: 2)
            }
        }
    }

    var budget: some View {
        VStack(spacing: 3) {
            ZStack {
                ThumbnailArc(progress: 1)
                    .stroke(Palette.line, style: Self.dialStroke)

                ThumbnailArc(progress: 0.62)
                    .stroke(Self.dialGradient, style: Self.dialStroke)
            }
            .frame(width: 32, height: 16)

            line(Palette.accentStrong, width: 18, opacity: 1)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    var templates: some View {
        Grid(horizontalSpacing: 3, verticalSpacing: 3) {
            ForEach(0..<2, id: \.self) { row in
                GridRow {
                    ForEach(0..<2, id: \.self) { column in
                        templateTile(color: Self.dots[row * 2 + column])
                    }
                }
            }
        }
    }

    var recent: some View {
        VStack(spacing: 3) {
            ForEach(Self.recentWidths.indices, id: \.self) { index in
                row(color: Self.dots[index], width: Self.recentWidths[index])
            }
        }
    }

    var bills: some View {
        VStack(spacing: 3) {
            ForEach(Self.billWidths.indices, id: \.self) { index in
                HStack(spacing: 3) {
                    RoundedRectangle(cornerRadius: 1)
                        .stroke(Palette.accent, lineWidth: 0.6)
                        .frame(width: 6, height: 6)

                    line(Palette.text, width: Self.billWidths[index])

                    Spacer(minLength: 0)

                    line(Palette.rose, width: 8, opacity: 0.8)
                }
            }
        }
    }

    var stamps: some View {
        HStack(spacing: 3) {
            ForEach(0..<4, id: \.self) { index in
                let isPressed = index < 2
                let fillColor = isPressed ? Palette.accent.opacity(.muted) : Color.clear
                let strokeOpacity = isPressed ? 1 : 0.5

                Circle()
                    .fill(fillColor)
                    .overlay {
                        Circle()
                            .stroke(Palette.accent.opacity(strokeOpacity), lineWidth: 0.8)
                    }
                    .overlay {
                        if isPressed {
                            Image(systemName: "checkmark")
                                .font(.system(size: 4, weight: .bold))
                                .foregroundStyle(Palette.accentStrong)
                        }
                    }
                    .frame(width: 9, height: 9)
            }
        }
    }

    func titled(_ body: some View) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            line(Palette.accent, width: 14, opacity: 0.8)

            body
        }
    }

    func templateTile(color: Color) -> some View {
        HStack(spacing: 2) {
            Circle()
                .fill(color)
                .frame(width: 4, height: 4)

            line(Palette.text, width: 9)
        }
        .frame(width: 20, height: 9)
        .background(Palette.faint, in: .rect(cornerRadius: 2))
        .overlay {
            RoundedRectangle(cornerRadius: 2)
                .stroke(Palette.outline, lineWidth: 0.5)
        }
    }

    func row(
        color: Color,
        width: CGFloat
    ) -> some View {
        HStack(spacing: 3) {
            Circle()
                .fill(color)
                .frame(width: 4, height: 4)

            line(Palette.text, width: width)

            Spacer(minLength: 0)

            line(Palette.accentStrong, width: 7, opacity: 0.8)
        }
    }

    func line(
        _ color: Color,
        width: CGFloat,
        opacity: Double = 0.45
    ) -> some View {
        Capsule()
            .fill(color.opacity(opacity))
            .frame(width: width, height: 2.5)
    }
}

private extension HomeSectionThumbnail {
    static let size = CGSize(width: 56, height: 40)
    static let dialStroke = StrokeStyle(lineWidth: 3, lineCap: .round)
    static let recentWidths: [CGFloat] = [18, 12, 16]
    static let billWidths: [CGFloat] = [16, 20]
    static let dots: [Color] = [Palette.rose, Palette.amber, Palette.saturday, Palette.accent]

    static var dialGradient: LinearGradient {
        LinearGradient(
            colors: [Palette.accent, Palette.accentStrong],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
}

private struct ThumbnailArc: Shape {
    let progress: Double

    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.maxY)
        let radius = min(rect.width / 2, rect.height) - 1.5
        let end = Angle.degrees(180 + 180 * progress)

        return Path { path in
            path.addArc(
                center: center,
                radius: radius,
                startAngle: .degrees(180),
                endAngle: end,
                clockwise: false
            )
        }
    }
}
