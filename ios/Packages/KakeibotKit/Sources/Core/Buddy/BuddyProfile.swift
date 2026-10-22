public struct BuddyProfile: Hashable, Sendable {
    public let buddy: Buddy?
    public let customName: String

    public init(
        buddy: Buddy?,
        customName: String
    ) {
        self.buddy = buddy
        self.customName = customName
    }
}

public extension BuddyProfile {
    var name: String {
        buddy?.name(customName) ?? ""
    }
}
