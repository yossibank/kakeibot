import Core
import SwiftUI

public struct BudgetUsageBar: View {
    let usage: BudgetUsage

    public init(_ usage: BudgetUsage) {
        self.usage = usage
    }

    public var body: some View {
        RatioBar(usage.progress, tint: usage.tint)
    }
}
