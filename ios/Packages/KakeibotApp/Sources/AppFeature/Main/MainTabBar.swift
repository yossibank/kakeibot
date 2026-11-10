import DesignSystem
import SwiftUI

struct MainTabBar: View {
    @Bindable var selection: MainTabSelection

    let hasSidebar: Bool
    let isAddHinted: Bool
    let onAdd: () -> Void

    var body: some View {
        if hasSidebar {
            SideTabBar(
                selection: $selection.value,
                title: "かけいぼっと",
                items: MainView.tabItems,
                isAddHinted: isAddHinted,
                onAdd: onAdd
            )
        } else {
            FloatingTabBar(
                selection: $selection.value,
                items: MainView.tabItems,
                isAddHinted: isAddHinted,
                onAdd: onAdd
            )
        }
    }
}
