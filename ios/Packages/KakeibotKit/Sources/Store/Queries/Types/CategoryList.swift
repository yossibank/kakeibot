import Core

public struct CategoryList: Equatable, Sendable {
    public let categories: [EntryCategory]
    public let tags: [EntryTag]
    public let icons: [Icon.ID: Icon]

    public init(
        categories: [EntryCategory],
        tags: [EntryTag],
        icons: [Icon.ID: Icon]
    ) {
        self.categories = categories
        self.tags = tags
        self.icons = icons
    }
}
