import Core
import DesignSystem
import SwiftUI

struct HomeCustomizeCard: View {
    @State private var changed: SetupItem?
    @State private var glowing: SetupItem?

    @Environment(\.themeStyle) private var themeStyle

    let model: SetupModel
    let appIcon: AppIconListModel
    let isSheetOpen: Bool
    let onOpen: (SetupItem) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HomeCardHeader(title: "自分好みにカスタマイズ") {
                Task {
                    await model.closeCustomizeCard()
                }
            }

            ScrollView(.horizontal) {
                HStack(spacing: 12) {
                    ForEach(SetupItem.customize) { item in
                        Button {
                            open(item)
                        } label: {
                            tile(item)
                        }
                        .buttonStyle(.plain)
                        .onChange(of: value(for: item)) {
                            if isSheetOpen {
                                changed = item
                            }
                        }
                    }
                }
            }
            .scrollIndicators(.hidden)
            .contentMargins(.horizontal, 14, for: .scrollContent)
            .contentMargins(.vertical, 6, for: .scrollContent)
            .scrollClipDisabled()
            .mask {
                Rectangle()
                    .padding(.vertical, -Self.shadowRoom)
            }
            .padding(.horizontal, -16)
            .padding(.vertical, -8)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
        .card()
        .onChange(of: isSheetOpen) { _, isOpen in
            guard
                !isOpen,
                let changed
            else {
                return
            }

            self.changed = nil

            glow(changed)
        }
        .task(id: glowing) {
            guard glowing != nil else {
                return
            }

            try? await Task.sleep(for: Self.glowDuration)

            withAnimation(.easeOut(duration: 0.6)) {
                glowing = nil
            }
        }
    }
}

private extension HomeCustomizeCard {
    func tile(_ item: SetupItem) -> some View {
        let shape = RoundedRectangle(
            cornerRadius: themeStyle.corner.radius(Self.cornerRadius)
        )

        return VStack(alignment: .leading, spacing: 4) {
            Image(systemName: item.systemImage)
                .sansFont(.body, weight: .light)
                .foregroundStyle(Palette.accent)

            Spacer(minLength: 8)

            Text(item.title)
                .textFont(.caption)
                .foregroundStyle(Palette.text)
                .lineLimit(1)
                .minimumScaleFactor(Self.textScale)

            Text(value(for: item))
                .textFont(.caption2)
                .foregroundStyle(Palette.subtext)
                .lineLimit(1)
                .minimumScaleFactor(Self.textScale)
                .contentTransition(.opacity)
        }
        .padding(12)
        .frame(width: Self.tileSize.width, height: Self.tileSize.height, alignment: .leading)
        .templateCardFace(cornerRadius: Self.cornerRadius, shadowRadius: 12)
        .overlay {
            shape
                .strokeBorder(Palette.accentStrong, lineWidth: 1.6)
                .shadow(color: Palette.glow, radius: 10)
                .opacity(glowOpacity(item))
        }
        .contentShape(.rect)
    }
}

private extension HomeCustomizeCard {
    static let tileSize = CGSize(width: 116, height: 96)
    static let cornerRadius: CGFloat = 18
    static let textScale: CGFloat = 0.7
    static let shadowRoom: CGFloat = 32
    static let glowDuration: Duration = .milliseconds(1200)

    func value(for item: SetupItem) -> String {
        switch item {
        case .launchScreen: model.launchScreen.title
        case .startsWithAmount: model.startsWithAmountTitle
        case .theme: model.themeTitle
        case .appIcon: appIcon.current.title
        case .themeStyle: themeStyle.shortTitle
        default: ""
        }
    }

    func glowOpacity(_ item: SetupItem) -> Double {
        glowing == item ? 1 : 0
    }

    func glow(_ item: SetupItem) {
        withAnimation(.easeOut(duration: 0.25)) {
            glowing = item
        }
    }

    func open(_ item: SetupItem) {
        guard item.isToggle else {
            onOpen(item)

            return
        }

        glow(item)

        Task {
            await model.setStartsWithAmount(!model.startsWithAmount)
        }
    }
}
