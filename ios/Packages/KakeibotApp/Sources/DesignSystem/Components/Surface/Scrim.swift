import SwiftUI

public struct Scrim: View {
    public enum Level {
        case drawer
        case menu
        case modal
    }

    private let level: Level

    public init(_ level: Level) {
        self.level = level
    }

    public var body: some View {
        Palette.scrim
            .opacity(opacity)
    }
}

private extension Scrim {
    var opacity: Double {
        switch level {
        case .drawer: 0.35
        case .menu: 0.45
        case .modal: 0.55
        }
    }
}
