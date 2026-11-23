import SwiftUI

public struct ChipLabel: View {
    let title: String
    let systemImage: String?

    public var body: some View {
        HStack(spacing: 4) {
            if let systemImage {
                Image(systemName: systemImage)
            }

            Text(title)
        }
        .lineLimit(1)
        .minimumScaleFactor(0.8)
    }
}
