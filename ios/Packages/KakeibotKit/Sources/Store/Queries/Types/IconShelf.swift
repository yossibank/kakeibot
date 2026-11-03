import Core

public struct IconShelf: Equatable, Sendable {
    public let shelfIcons: [ShelfIcon]
    public let icons: [Icon.ID: Icon]

    public init(
        shelfIcons: [ShelfIcon],
        icons: [Icon.ID: Icon]
    ) {
        self.shelfIcons = shelfIcons
        self.icons = icons
    }
}
