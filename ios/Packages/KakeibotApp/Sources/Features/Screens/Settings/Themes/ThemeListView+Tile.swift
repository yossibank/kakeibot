import Core
import DesignSystem
import SwiftUI

extension ThemeListView {
    func tile(
        _ choice: ThemeChoice,
        palette: ThemePalette,
        title: String,
        theme: Theme?
    ) -> some View {
        let isCurrent = choice == model.current
        let titleColor = isCurrent ? Palette.accentStrong : Palette.subtext
        let scale: CGFloat = pressing == choice ? 0.94 : 1

        return VStack(spacing: 8) {
            preview(palette, isCurrent: isCurrent)
                .scaleEffect(scale)
                .animation(.snappy(duration: 0.2), value: scale)
                .overlay {
                    GeometryReader { proxy in
                        Color.clear
                            .contentShape(.rect)
                            .onTapGesture {
                                tap(choice, theme: theme)
                            }
                            .onLongPressGesture(minimumDuration: Self.menuPressDuration) {
                                let space = CoordinateSpace.named(Self.space)

                                let menu = Menu(
                                    choice: choice,
                                    palette: palette,
                                    title: title,
                                    theme: theme,
                                    frame: proxy.frame(in: space)
                                )

                                openMenu(menu)
                            } onPressingChanged: { isPressing in
                                pressing = isPressing ? choice : nil
                            }
                    }
                }

            Text(title)
                .textFont(.footnote)
                .foregroundStyle(titleColor)
                .sharedTextScale()
        }
    }

    func preview(
        _ palette: ThemePalette,
        isCurrent: Bool
    ) -> some View {
        framed(ThemePreview(palette: palette), isCurrent: isCurrent)
    }

    func framed(
        _ content: some View,
        isCurrent: Bool
    ) -> some View {
        let ring = isCurrent ? Palette.accent : Color.clear

        return content
            .padding(4)
            .overlay {
                RoundedRectangle(cornerRadius: corner.radius(20))
                    .stroke(ring, lineWidth: 2)
            }
            .overlay(alignment: .bottomTrailing) {
                if isCurrent {
                    Image(systemName: "checkmark.circle.fill")
                        .sansFont(.headline)
                        .foregroundStyle(Palette.accent, Palette.background)
                        .offset(x: 6, y: 6)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .animation(.spring(duration: 0.3), value: isCurrent)
    }
}

private extension ThemeListView {
    static let menuPressDuration = 0.4

    func tap(
        _ choice: ThemeChoice,
        theme: Theme?
    ) {
        if let theme,
           choice == model.current {
            editing = .edit(theme)
        } else {
            select(choice)
        }
    }
}
