import SwiftUI

public struct TallFormSizing: PresentationSizing {
    public init() {}

    public func proposedSize(
        for root: PresentationSizingRoot,
        context: PresentationSizingContext
    ) -> ProposedViewSize {
        ProposedViewSize(width: Self.width, height: Self.height)
    }
}

public extension PresentationSizing where Self == TallFormSizing {
    static var tallForm: TallFormSizing {
        TallFormSizing()
    }
}

private extension TallFormSizing {
    static let width: CGFloat = 580
    static let height: CGFloat = 800
}
