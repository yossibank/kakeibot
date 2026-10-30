import Core
import DesignSystem
import SwiftUI

struct ThemeStyleTabBar: View {
    var body: some View {
        Color.clear
            .aspectRatio(Self.width / Self.height, contentMode: .fit)
            .overlay(alignment: .topLeading) {
                GeometryReader { proxy in
                    FloatingTabBar(
                        selection: .constant(LaunchScreen.home),
                        items: LaunchScreen.tabItems,
                        onAdd: {}
                    )
                    .frame(width: Self.width, height: Self.height)
                    .scaleEffect(proxy.size.width / Self.width, anchor: .topLeading)
                }
            }
            .allowsHitTesting(false)
    }
}

private extension ThemeStyleTabBar {
    static let width: CGFloat = 340
    static let height = FloatingTabBar<LaunchScreen>.clearance
}
