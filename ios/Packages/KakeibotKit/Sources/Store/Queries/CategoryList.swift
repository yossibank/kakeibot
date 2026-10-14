import Core

public struct CategoryList: Equatable, Sendable {
    public let categories: [EntryCategory]
    public let icons: [Icon.ID: Icon]

    public init(
        categories: [EntryCategory],
        icons: [Icon.ID: Icon]
    ) {
        self.categories = categories
        self.icons = icons
    }
}
