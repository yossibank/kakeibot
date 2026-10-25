import Core
import DesignSystem
import SwiftUI

struct LaunchScreenPreview: View {
    let selection: LaunchScreen

    var body: some View {
        FloatingTabBar(
            selection: .constant(selection),
            items: Self.items,
            isAddHinted: selection == .entry,
            onAdd: {}
        )
        .allowsHitTesting(false)
        .animation(.snappy(duration: 0.25), value: selection)
    }
}

private extension LaunchScreenPreview {
    static let tabs: [LaunchScreen] = [.home, .records, .review, .assets]

    static let items: [FloatingTabBar<LaunchScreen>.Item] = tabs.map { screen in
        .init(screen.title, systemImage: screen.systemImage, value: screen)
    }
}
