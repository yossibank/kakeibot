import SwiftUI

public struct TallFormSizing: PresentationSizing {
    public init() {}
}

public extension TallFormSizing {
    func proposedSize(
        for root: PresentationSizingRoot,
        context: PresentationSizingContext
    ) -> ProposedViewSize {
        ProposedViewSize(width: Self.width, height: Self.height)
    }
}

private extension TallFormSizing {
    static let width: CGFloat = 580
    static let height: CGFloat = 800
}

public extension PresentationSizing where Self == TallFormSizing {
    static var tallForm: TallFormSizing {
        TallFormSizing()
    }
}
