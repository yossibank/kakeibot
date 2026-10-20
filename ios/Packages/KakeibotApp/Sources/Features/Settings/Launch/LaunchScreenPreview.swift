import Core
import DesignSystem
import SwiftUI

struct LaunchScreenPreview: View {
    let selection: LaunchScreen

    var body: some View {
        HStack(spacing: 10) {
            HStack(spacing: 2) {
                ForEach(Self.tabs, id: \.self) { screen in
                    tab(screen)
                }
            }
            .padding(4)
            .background(Palette.panel, in: Capsule())
            .overlay {
                Capsule()
                    .strokeBorder(Palette.accent.opacity(.soft), lineWidth: 1)
            }

            entryButton
        }
        .animation(.snappy(duration: 0.25), value: selection)
    }
}

private extension LaunchScreenPreview {
    var entryButton: some View {
        let isSelected = selection == .entry
        let fill = isSelected ? Palette.accent : Palette.panel
        let color = isSelected ? Palette.backgroundBottom : Palette.accent
        let scale: CGFloat = isSelected ? 1.08 : 1

        return Image(systemName: "plus")
            .font(.sans(.body, weight: .light))
            .foregroundStyle(color)
            .frame(width: 48, height: 48)
            .background(fill, in: Circle())
            .overlay {
                Circle()
                    .strokeBorder(Palette.accent.opacity(.medium), lineWidth: 1)
            }
            .scaleEffect(scale)
    }

    func tab(_ screen: LaunchScreen) -> some View {
        let isSelected = selection == screen
        let fill = isSelected ? Palette.accent.opacity(.subtle) : Color.clear
        let color = isSelected ? Palette.accentStrong : Palette.subtext

        return VStack(spacing: 2) {
            Image(systemName: screen.systemImage)
                .font(.sans(.small, weight: .light))

            Text(screen.title)
                .textFont(size: .micro)
        }
        .foregroundStyle(color)
        .frame(width: 52, height: 40)
        .background(fill, in: Capsule())
    }
}

private extension LaunchScreenPreview {
    static let tabs: [LaunchScreen] = [.home, .records, .review, .assets]
}
