import SwiftUI

struct MainTabLayer<Content: View>: View {
    let selection: MainTabSelection
    let value: MainView.MainTab

    @ViewBuilder let content: Content

    var body: some View {
        if selection.visited.contains(value) {
            let isShown = selection.value == value

            content
                .opacity(isShown ? 1 : 0)
                .allowsHitTesting(isShown)
                .zIndex(isShown ? 1 : 0)
                .animation(nil, value: isShown)
        }
    }
}
