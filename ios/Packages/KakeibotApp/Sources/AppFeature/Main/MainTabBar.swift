import DesignSystem
import FeatureModels
import SwiftUI

struct MainTabBar: View {
    let state: MainModel.State
    let hasSidebar: Bool
    let isAddHinted: Bool
    let onAdd: () -> Void

    var body: some View {
        if hasSidebar {
            SideTabBar(
                selection: selection,
                title: "かけいぼっと",
                items: MainView.tabItems,
                isAddHinted: isAddHinted,
                onAdd: onAdd
            )
        } else {
            FloatingTabBar(
                selection: selection,
                items: MainView.tabItems,
                isAddHinted: isAddHinted,
                onAdd: onAdd
            )
        }
    }
}

private extension MainTabBar {
    var selection: Binding<MainModel.Tab> {
        Binding {
            state.tab
        } set: { tab in
            state.select(tab)
        }
    }
}
