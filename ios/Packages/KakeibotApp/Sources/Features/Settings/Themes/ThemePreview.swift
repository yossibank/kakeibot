import Core
import DesignSystem
import SwiftUI

struct ThemePreview: View {
    let palette: ThemePalette

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            VStack(alignment: .leading, spacing: 6) {
                Capsule()
                    .fill(Palette.subtext)
                    .frame(width: 24, height: 3)

                Text("¥1,280")
                    .font(.serif(.small))
                    .foregroundStyle(Palette.accentStrong)

                Capsule()
                    .fill(Palette.accent)
                    .frame(height: 3)
            }
            .padding(8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Palette.card, in: .rect(cornerRadius: 8))
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Palette.outline, lineWidth: 0.5)
            }

            ForEach(Self.rows, id: \.self) { width in
                HStack(spacing: 6) {
                    Circle()
                        .fill(Palette.accent.opacity(.muted))
                        .frame(width: 10, height: 10)

                    Capsule()
                        .fill(Palette.text)
                        .frame(width: width, height: 3)

                    Spacer(minLength: 0)

                    Capsule()
                        .fill(Palette.hint)
                        .frame(width: 14, height: 3)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(8)
        .frame(height: 132)
        .background(Palette.background, in: .rect(cornerRadius: 14))
        .environment(\.palette, palette)
    }
}

private extension ThemePreview {
    static let rows: [CGFloat] = [28, 20, 34]
}
