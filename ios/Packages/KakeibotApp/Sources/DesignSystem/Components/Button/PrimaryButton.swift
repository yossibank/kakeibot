import SwiftUI

public struct PrimaryButton: View {
    let title: String
    let subject: String?
    let detail: String?
    let action: () -> Void

    public init(
        _ title: String,
        subject: String? = nil,
        detail: String? = nil,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.subject = subject
        self.detail = detail
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            VStack(spacing: 1) {
                HStack(spacing: 4) {
                    if let subject {
                        Text(subject)
                    }

                    Text(title)
                        .layoutPriority(1)
                }
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

        PrimaryButton("¥1,280 を記録する", subject: "食費", detail: "今日・財布から") {}

        PrimaryButton("金額を入れてください") {}
            .disabled(true)
    }
    .padding()
    .background(Palette.background)
}
