import Core
import DesignSystem
import SwiftUI

extension ThemeListView {
    struct Menu: Equatable {
        let choice: ThemeChoice
        let palette: ThemePalette
        let title: String
        let theme: Theme?
        let frame: CGRect
    }

    @ViewBuilder
    func menuLayer(_ menu: Menu) -> some View {
        Palette.scrim
            .opacity(0.45)
            .ignoresSafeArea()
            .onTapGesture {
                closeMenu()
            }
            .transition(.opacity)

        preview(menu.palette, isCurrent: menu.choice == model.current)
            .frame(width: menu.frame.width, height: menu.frame.height)
            .scaleEffect(1.04)
            .glow(Palette.glow.opacity(.muted), radius: 12)
            .position(x: menu.frame.midX, y: menu.frame.midY)
            .allowsHitTesting(false)
            .transition(.opacity)

        MenuPanel(width: Self.menuWidth) {
            MenuHeader(menu.title) {
                Circle()
                    .fill(Palette.backgroundTop)
                    .overlay {
                        Circle()
                            .strokeBorder(Palette.accent, lineWidth: 2)
                    }
                    .frame(width: 16, height: 16)
                    .environment(\.palette, menu.palette)
            }

            MenuDivider()

            MenuRow(
                "これをもとにつくる",
                note: "この色から新しくつくります",
                systemImage: "plus.square.on.square"
            ) {
                closeMenu()
                editing = .new(base: menu.palette)
            }

            if let theme = menu.theme {
                MenuDivider()

                MenuRow(
                    "このテーマを編集",
                    systemImage: "square.and.pencil"
                ) {
                    closeMenu()
                    editing = .edit(theme)
                }
            }
        }
        .onGeometryChange(for: CGFloat.self) { proxy in
            proxy.size.height
        } action: { height in
            menuHeight = height
        }
        .offset(x: menuX(for: menu), y: menuY(for: menu))
        .transition(.opacity.combined(with: .scale(scale: 0.96)))
    }
}

extension ThemeListView {
    func openMenu(_ menu: Menu) {
        pressing = nil

        withAnimation(.snappy(duration: 0.25)) {
            self.menu = menu
        }
    }
}

private extension ThemeListView {
    static let menuWidth: CGFloat = 236
    static let menuInset: CGFloat = 20
    static let menuGap: CGFloat = 12

    func closeMenu() {
        withAnimation(.snappy(duration: 0.2)) {
            menu = nil
        }
    }

    func menuX(for menu: Menu) -> CGFloat {
        let preferred = menu.frame.midX - Self.menuWidth / 2
        let limit = size.width - Self.menuWidth - Self.menuInset

        return min(max(preferred, Self.menuInset), limit)
    }

    func menuY(for menu: Menu) -> CGFloat {
        let below = menu.frame.maxY + Self.menuGap
        let fitsBelow = below + menuHeight <= size.height - Self.menuInset

        guard !fitsBelow else {
            return below
        }

        return menu.frame.minY - Self.menuGap - menuHeight
    }
}
