import Core
import DesignSystem
import SwiftUI

struct LaunchScreenPreview: View {
    let selection: LaunchScreen

    var body: some View {
        FloatingTabBar(
            selection: .constant(selection),
            items: LaunchScreen.tabItems,
            isAddHinted: selection == .entry,
            onAdd: {}
        )
        .allowsHitTesting(false)
        .animation(.snappy(duration: 0.25), value: selection)
    }
}
