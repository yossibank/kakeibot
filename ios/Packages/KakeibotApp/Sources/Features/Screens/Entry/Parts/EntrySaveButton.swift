import DesignSystem
import SwiftUI

struct EntrySaveButton: View {
    let label: EntryModel.SaveLabel
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            content
                .padding(.horizontal, 20)
                .frame(maxWidth: .infinity, minHeight: 56)
                .goldFace()
        }
        .buttonStyle(.plain)
    }
}

private extension EntrySaveButton {
    struct Part {
        let text: String
        let isFixed: Bool
    }
}

private extension EntrySaveButton {
    var fullParts: [Part] {
        [label.category, label.day, label.wallets, label.fee]
            .compactMap(\.self)
            .map { Part(text: $0, isFixed: true) }
    }

    var routeParts: [Part] {
        [label.day, label.wallets, label.fee]
            .compactMap(\.self)
            .map { Part(text: $0, isFixed: true) }
    }

    var feeParts: [Part] {
        [label.day, label.fee]
            .compactMap(\.self)
            .map { Part(text: $0, isFixed: true) }
    }

    var compactParts: [Part] {
        [
            label.day.map { Part(text: $0, isFixed: true) },
            label.wallets.map { Part(text: $0, isFixed: false) }
        ]
        .compactMap(\.self)
    }
}

private extension EntrySaveButton {
    @ViewBuilder
    var content: some View {
        if let amount = label.amount {
            ViewThatFits(in: .horizontal) {
                sideLayout(amount)
                stackedLayout(amount)
            }
        } else {
            ViewThatFits(in: .horizontal) {
                Text(label.title)
                    .textFont(.body, weight: .bold)
                    .lineLimit(1)

                Text(label.title)
                    .textFont(.subheadline, weight: .bold)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
        }
    }

    var titleText: some View {
        Text(label.title)
            .textFont(.body, weight: .bold)
            .lineLimit(1)
            .fixedSize()
    }

    var detailLine: some View {
        ViewThatFits(in: .horizontal) {
            partsLine(fullParts)
            partsLine(routeParts)

            if label.fee != nil {
                partsLine(feeParts)
            }

            partsLine(compactParts)
        }
        .textFont(.caption2)
        .monospacedDigit()
        .lineLimit(1)
        .frame(idealWidth: 0, alignment: .leading)
    }

    func amountText(
        _ amount: String,
        size: FontSize
    ) -> some View {
        Text(amount)
            .displayFont(size, weight: .bold)
            .monospacedDigit()
            .lineLimit(1)
            .minimumScaleFactor(0.9)
    }

    func sideLayout(_ amount: String) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 1) {
                titleText

                detailLine
            }

            Spacer(minLength: 0)

            amountText(amount, size: .headline)
                .fixedSize()
        }
    }

    func stackedLayout(_ amount: String) -> some View {
        VStack(spacing: 1) {
            amountText(amount, size: .body)

            HStack(spacing: 4) {
                Text(label.title)
                    .textFont(.caption2, weight: .bold)
                    .lineLimit(1)
                    .fixedSize()

                if !compactParts.isEmpty {
                    Text("·")
                        .textFont(.caption2)
                        .fixedSize()

                    detailLine
                }
            }
            .frame(idealWidth: 0)
        }
    }

    func partsLine(_ parts: [Part]) -> some View {
        HStack(spacing: 4) {
            ForEach(Array(parts.enumerated()), id: \.offset) { index, part in
                if index > 0 {
                    Text("·")
                        .fixedSize()
                }

                if part.isFixed {
                    Text(part.text)
                        .fixedSize()
                } else {
                    Text(part.text)
                }
            }
        }
    }
}
