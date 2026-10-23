import Core
import SwiftUI

public struct BuddyFace: View {
    let buddy: Buddy
    let size: CGFloat

    public init(
        _ buddy: Buddy,
        size: CGFloat
    ) {
        self.buddy = buddy
        self.size = size
    }

    public var body: some View {
        Image(imageName, bundle: .main)
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
    }
}

private extension BuddyFace {
    var imageName: String {
        switch buddy {
        case .rabbit: "BuddyRabbit"
        case .panda: "BuddyPanda"
        case .pig: "BuddyPig"
        case .penguin: "BuddyPenguin"
        case .monkey: "BuddyMonkey"
        case .elephant: "BuddyElephant"
        case .giraffe: "BuddyGiraffe"
        case .hippo: "BuddyHippo"
        case .parrot: "BuddyParrot"
        case .snake: "BuddySnake"
        }
    }
}

#Preview {
    LazyVGrid(
        columns: Array(repeating: GridItem(), count: 5),
        spacing: 16
    ) {
        ForEach(Buddy.allCases, id: \.self) { buddy in
            BuddyFace(buddy, size: 56)
        }
    }
    .padding()
    .background(Palette.background)
}
