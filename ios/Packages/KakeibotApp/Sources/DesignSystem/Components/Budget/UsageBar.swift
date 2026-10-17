import Core
import SwiftUI

public struct UsageBar: View {
    let usage: BudgetUsage

    public init(_ usage: BudgetUsage) {
        self.usage = usage
    }

    public var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Palette.line)

                Capsule()
                    .fill(usage.tint)
                    .frame(width: proxy.size.width * usage.progress)
            }
        }
        .frame(height: 3)
        .animation(.snappy, value: usage)
    }
}
