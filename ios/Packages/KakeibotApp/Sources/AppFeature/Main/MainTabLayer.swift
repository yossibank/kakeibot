import FeatureModels
import SwiftUI

struct MainTabLayer<Content: View>: View {
    let state: MainModel.State
    let value: MainModel.Tab

    @ViewBuilder let content: Content

    var body: some View {
        if state.visitedTabs.contains(value) {
            let isShown = state.tab == value

            content
                .opacity(isShown ? 1 : 0)
                .allowsHitTesting(isShown)
                .zIndex(isShown ? 1 : 0)
                .animation(nil, value: isShown)
        }
    }
}
