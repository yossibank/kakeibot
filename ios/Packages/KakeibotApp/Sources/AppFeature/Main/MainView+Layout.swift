import DesignSystem
import SwiftUI

extension MainView {
    enum MainTab: Hashable {
        case home
        case records
        case review
        case assets
    }

    static func hasSidebar(_ sizeClass: UserInterfaceSizeClass?) -> Bool {
        sizeClass == .regular
    }

    static func noticeLeading(hasSidebar: Bool) -> CGFloat {
        hasSidebar ? SideTabBar<Int>.width : 0
    }

    static func noticeBottom(hasSidebar: Bool) -> CGFloat {
        hasSidebar ? 12 : FloatingTabBar<Int>.height + 24
    }
}

extension MainView {
    static let warmupDuration: Duration = .milliseconds(500)

    static let tabItems: [FloatingTabBar<MainTab>.Item] = [
        .init("ホーム", systemImage: "house", value: .home),
        .init("記録", systemImage: "calendar", value: .records),
        .init("振り返り", systemImage: "chart.pie", value: .review),
        .init("資産", systemImage: "building.columns", value: .assets)
    ]
}

extension View {
    func tabContent() -> some View {
        modifier(TabContent())
    }
}

private struct TabContent: ViewModifier {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    func body(content: Content) -> some View {
        let hasSidebar = MainView.hasSidebar(horizontalSizeClass)
        let leading = hasSidebar ? SideTabBar<Int>.width : 0
        let bottom = hasSidebar ? 0 : FloatingTabBar<Int>.clearance

        content
            .toolbar(.hidden, for: .tabBar)
            .safeAreaPadding(.leading, leading)
            .safeAreaPadding(.bottom, bottom)
    }
}
