import Core
import SwiftUI

public enum TemplateCardSize: Sendable {
    case regular
    case large
}

public extension TemplateCardSize {
    var textSpacing: CGFloat {
        switch self {
        case .regular: 3
        case .large: 10
        }
    }

    var height: CGFloat {
        switch self {
        case .regular: 116
        case .large: 172
        }
    }

    func nameFont(in font: ThemeFont) -> Font {
        switch self {
        case .regular: .display(.body, weight: .medium, in: font)
        case .large: .display(.headline, weight: .medium, in: font)
        }
    }

    func amountFont(in font: ThemeFont) -> Font {
        switch self {
        case .regular: .display(.headline, weight: .medium, in: font)
        case .large: .display(.largeTitle, weight: .medium, in: font)
        }
    }

    func emptyAmountFont(in font: ThemeFont) -> Font {
        switch self {
        case .regular: .display(.small, in: font)
        case .large: .display(.body, in: font)
        }
    }
}

extension TemplateCardSize {
    var nameLines: Int {
        switch self {
        case .regular: 2
        case .large: 1
        }
    }

    var detailFont: Font {
        switch self {
        case .regular: .sans(.caption)
        case .large: .caption
        }
    }

    var iconSize: CGFloat {
        switch self {
        case .regular: 16
        case .large: 24
        }
    }

    var badgeSize: CGFloat {
        switch self {
        case .regular: 34
        case .large: 52
        }
    }

    var gap: CGFloat {
        switch self {
        case .regular: 10
        case .large: 14
        }
    }

    var spacing: CGFloat {
        switch self {
        case .regular: 10
        case .large: 16
        }
    }

    var padding: CGFloat {
        switch self {
        case .regular: 14
        case .large: 22
        }
    }

    var amountHeight: CGFloat {
        switch self {
        case .regular: 26
        case .large: 42
        }
    }

    var cornerRadius: CGFloat {
        switch self {
        case .regular: 20
        case .large: 26
        }
    }

    var shadowRadius: CGFloat {
        switch self {
        case .regular: 12
        case .large: 24
        }
    }
}
