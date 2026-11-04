import DesignSystem
import SwiftUI

struct SettingsDetails<Content: View>: View {
    @Binding var isOpen: Bool

    @Environment(\.themeStyle.corner) private var corner

    let chips: [String]
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button {
                withAnimation(.snappy) {
                    isOpen.toggle()
                }
            } label: {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 12) {
                        Image(systemName: "slider.horizontal.3")
                            .sansFont(.small)
                            .foregroundStyle(Palette.accent)
                            .frame(width: 28, height: 28)
                            .background(Palette.accent.opacity(.subtle), in: Circle())

                        Text("くわしい設定")
                            .textFont(.subheadline)
                            .foregroundStyle(Palette.accentStrong)

                        Spacer(minLength: 8)

                        Image(systemName: "chevron.down")
                            .sansFont(.small)
                            .foregroundStyle(Palette.accent.opacity(.medium))
                            .rotationEffect(.degrees(isOpen ? 180 : 0))
                    }

                    if !isOpen {
                        LazyVGrid(columns: Self.chipColumns, alignment: .leading, spacing: 8) {
                            ForEach(chips, id: \.self) { chip in
                                Text(chip)
                                    .textFont(.caption)
                                    .monospacedDigit()
                                    .foregroundStyle(Palette.subtext)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.8)
                                    .padding(.horizontal, 12)
                                    .frame(maxWidth: .infinity, minHeight: 28)
                                    .background(Palette.accent.opacity(.faint), in: Capsule())
                            }
                        }
                        .transition(.opacity)
                    }
                }
                .padding(16)
                .background(SettingsTile.cardFill.opacity(0.7), in: shape)
                .overlay {
                    shape
                        .stroke(Palette.accent.opacity(.soft), lineWidth: 1)
                }
                .contentShape(.rect)
            }
            .buttonStyle(.plain)

            if isOpen {
                content()
                    .transition(.opacity)
            }
        }
    }
}

private extension SettingsDetails {
    static var chipColumns: [GridItem] {
        Array(
            repeating: GridItem(
                .flexible(),
                spacing: 8
            ),
            count: 2
        )
    }

    var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: corner.radius(20))
    }
}
