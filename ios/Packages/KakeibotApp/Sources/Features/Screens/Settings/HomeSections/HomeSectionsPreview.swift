import Core
import DesignSystem
import SwiftUI

struct HomeSectionsPreview: View {
    @Environment(\.themeStyle.corner) private var corner

    let sections: [HomeSection]

    var body: some View {
        SettingsScreenPreview {
            VStack(spacing: 12) {
                header

                ForEach(sections) { section in
                    block(section)
                        .transition(.opacity.combined(with: .scale(scale: 0.96, anchor: .top)))
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 56)
        }
    }
}

private extension HomeSectionsPreview {
    var header: some View {
        HStack(spacing: 8) {
            line(Palette.accent, width: 44, height: 14)

            line(Palette.subtext, width: 72, height: 8)

            Spacer()

            Circle()
                .fill(Palette.panel)
                .overlay {
                    Circle()
                        .stroke(Palette.outline, lineWidth: 1)
                }
                .frame(width: 40, height: 40)
        }
        .padding(.horizontal, 4)
    }

    var customize: some View {
        VStack(alignment: .leading, spacing: 12) {
            line(Palette.accentStrong, width: 120, height: 9)

            HStack(spacing: 8) {
                ForEach(0..<3, id: \.self) { _ in
                    customizeTile
                }
            }
        }
        .padding(16)
        .card()
    }

    var customizeTile: some View {
        VStack(alignment: .leading, spacing: 10) {
            Circle()
                .stroke(Palette.accent.opacity(.muted), lineWidth: 1)
                .frame(width: 18, height: 18)

            line(Palette.text, width: 52, height: 7)

            line(Palette.subtext, width: 32, height: 6)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Palette.card, in: .rect(cornerRadius: corner.radius(16)))
        .overlay {
            RoundedRectangle(cornerRadius: corner.radius(16))
                .stroke(Palette.outline, lineWidth: 0.8)
        }
    }

    var budget: some View {
        VStack(spacing: 16) {
            ZStack(alignment: .bottom) {
                HalfDial(progress: 0.4)

                VStack(spacing: 8) {
                    line(Palette.accent, width: 72, height: 8)

                    line(Palette.accentStrong, width: 160, height: 30)
                }
            }
            .frame(maxWidth: 290)

            line(Palette.subtext, width: 180, height: 8)

            HStack {
                ForEach(0..<3, id: \.self) { _ in
                    VStack(spacing: 6) {
                        line(Palette.subtext, width: 28, height: 7)

                        line(Palette.accentStrong, width: 48, height: 10)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(16)
        .card()
    }

    var templates: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                line(Palette.accent, width: 80, height: 9)

                Capsule()
                    .stroke(Palette.outline, lineWidth: 1)
                    .frame(width: 112, height: 32)

                Spacer()

                line(Palette.accent, width: 32, height: 8)
            }

            HStack(spacing: 8) {
                ForEach(0..<3, id: \.self) { _ in
                    templateTile
                }
            }
        }
        .padding(16)
        .card()
    }

    var templateTile: some View {
        VStack(alignment: .leading, spacing: 10) {
            Circle()
                .fill(Palette.accent.opacity(.muted))
                .frame(width: 26, height: 26)

            line(Palette.text, width: 52, height: 7)

            line(Palette.accentStrong, width: 40, height: 11)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Palette.card, in: .rect(cornerRadius: corner.radius(16)))
        .overlay {
            RoundedRectangle(cornerRadius: corner.radius(16))
                .stroke(Palette.outline, lineWidth: 0.8)
        }
    }

    var recent: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                line(Palette.accent, width: 80, height: 9)

                Spacer()

                line(Palette.accent, width: 32, height: 8)
            }
            .padding(.vertical, 12)

            ForEach(Self.recentWidths, id: \.self) { width in
                Hairline()

                HStack(spacing: 12) {
                    Circle()
                        .fill(Palette.accent.opacity(.subtle))
                        .frame(width: 32, height: 32)

                    VStack(alignment: .leading, spacing: 6) {
                        line(Palette.text, width: width, height: 8)

                        line(Palette.hint, width: 48, height: 6)
                    }

                    Spacer()

                    line(Palette.accentStrong, width: 56, height: 10)
                }
                .padding(.vertical, 12)
            }
        }
        .padding(.horizontal, 16)
        .card()
    }

    var bills: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                line(Palette.accent, width: 120, height: 9)

                Spacer()

                line(Palette.subtext, width: 64, height: 8)
            }
            .padding(.vertical, 12)

            ForEach(Self.billWidths, id: \.self) { width in
                Hairline()

                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 6) {
                        line(Palette.accent, width: 32, height: 10)

                        line(Palette.hint, width: 28, height: 6)
                    }
                    .frame(width: 40, alignment: .leading)

                    line(Palette.text, width: width, height: 8)

                    Spacer()

                    line(Palette.accentStrong, width: 56, height: 10)
                }
                .padding(.vertical, 12)
            }
        }
        .padding(.horizontal, 16)
        .card()
    }

    var stamps: some View {
        VStack(alignment: .leading, spacing: 12) {
            line(Palette.accent, width: 96, height: 9)

            HStack(spacing: 16) {
                ForEach(0..<3, id: \.self) { _ in
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Palette.accent.opacity(.subtle))
                            .frame(width: 26, height: 26)

                        line(Palette.accentStrong, width: 20, height: 10)
                    }
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .card()
    }

    @ViewBuilder
    func block(_ section: HomeSection) -> some View {
        switch section {
        case .customize: customize
        case .budget: budget
        case .templates: templates
        case .recent: recent
        case .bills: bills
        case .stamps: stamps
        }
    }

    func line(
        _ color: Color,
        width: CGFloat,
        height: CGFloat
    ) -> some View {
        Capsule()
            .fill(color.opacity(.muted))
            .frame(width: width, height: height)
    }
}

private extension HomeSectionsPreview {
    static let recentWidths: [CGFloat] = [96, 72, 112]
    static let billWidths: [CGFloat] = [88, 104]
}
