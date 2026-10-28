import DesignSystem
import SwiftUI

struct SettingsEditHeader: View {
    @State private var isMenuOpen = false

    @Environment(\.isSettingsEditPushed) private var isPushed

    let title: String
    let isEditing: Bool
    let isHidden: Bool
    var canHide = true
    var canDelete = true
    let onClose: () -> Void
    let onHide: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack {
            RingButton(systemImage: closeImage, action: onClose)
                .frame(width: Self.sideWidth, alignment: .leading)

            Spacer()

            SheetTitle(title)

            Spacer()

            ZStack {
                if isEditing {
                    RingButton(systemImage: "ellipsis", style: menuStyle) {
                        openMenu(true)
                    }
                }
            }
            .frame(width: Self.sideWidth, alignment: .trailing)
        }
        .overlay {
            if isMenuOpen {
                scrim
            }
        }
        .overlay(alignment: .topTrailing) {
            if isMenuOpen {
                menu
            }
        }
        .zIndex(1)
        .sensoryFeedback(.impact(weight: .medium), trigger: isMenuOpen) { _, isOpen in
            isOpen
        }
    }
}

extension EnvironmentValues {
    @Entry var isSettingsEditPushed = false
}

private extension SettingsEditHeader {
    var scrim: some View {
        Palette.scrim
            .opacity(0.45)
            .frame(width: Self.scrimSize, height: Self.scrimSize)
            .ignoresSafeArea()
            .onTapGesture {
                openMenu(false)
            }
            .transition(.opacity)
    }

    var menu: some View {
        MenuPanel(width: Self.menuWidth) {
            if canHide {
                MenuRow(hideTitle, systemImage: hideImage) {
                    openMenu(false)
                    onHide()
                }
            }

            if canHide, canDelete {
                MenuDivider()
            }

            if canDelete {
                MenuRow("削除", systemImage: "trash", isDestructive: true) {
                    openMenu(false)
                    onDelete()
                }
            }
        }
        .offset(y: Self.menuTop)
        .transition(.scale(scale: 0.95, anchor: .topTrailing).combined(with: .opacity))
    }
}

private extension SettingsEditHeader {
    static let sideWidth: CGFloat = 44
    static let menuWidth: CGFloat = 236
    static let menuTop: CGFloat = 48
    static let scrimSize: CGFloat = 4000

    var closeImage: String {
        isPushed ? "chevron.left" : "xmark"
    }

    var menuStyle: RingButton.Style {
        isHidden ? .prominent : .plain
    }

    var hideTitle: String {
        isHidden ? "表示に戻す" : "非表示にする"
    }

    var hideImage: String {
        isHidden ? "eye" : "eye.slash"
    }

    func openMenu(_ isOpen: Bool) {
        withAnimation(.snappy(duration: 0.25)) {
            isMenuOpen = isOpen
        }
    }
}
