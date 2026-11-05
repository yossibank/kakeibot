import SwiftUI

public struct PrimaryButton: View {
    let title: String
    let detail: String?
    let action: () -> Void

    public init(
        _ title: String,
        detail: String? = nil,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.detail = detail
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            VStack(spacing: 1) {
                Text(title)
                    .textFont(.body, weight: .bold)

                if let detail {
                    Text(detail)
                        .textFont(.caption2)
                }
            }
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity, minHeight: 56)
            .goldFace()
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    VStack(spacing: 16) {
        PrimaryButton("¥12,800 を記録する") {}

        PrimaryButton("予算を決めて始める", detail: "1 分") {}

        PrimaryButton("金額を入れてください") {}
            .disabled(true)
    }
    .padding()
    .background(Palette.background)
}
