import DesignSystem
import SwiftUI

public struct SetupList: View {
    private let items: [SetupItem]
    private let model: SetupModel
    private let onOpen: (SetupItem) -> Void

    public init(
        _ items: [SetupItem],
        model: SetupModel,
        onOpen: @escaping (SetupItem) -> Void
    ) {
        self.items = items
        self.model = model
        self.onOpen = onOpen
    }

    public var body: some View {
        VStack(spacing: 0) {
            ForEach(items) { item in
                if item != items.first {
                    Hairline()
                }

                if item.isToggle {
                    toggleRow(item)
                } else {
                    Button {
                        onOpen(item)
                    } label: {
                        row(item)
                    }
                }
            }
        }
        .buttonStyle(.plain)
    }
}

private extension SetupList {
    func toggleRow(_ item: SetupItem) -> some View {
        HStack(spacing: 12) {
            Image(systemName: item.systemImage)
                .sansFont(.body, weight: .light)
                .foregroundStyle(Palette.accent)
                .frame(width: 22)

            Text(item.title)
                .textFont(.subheadline)
                .foregroundStyle(Palette.text)
                .lineLimit(1)

            Spacer()

            CapsulePicker(
                selection: startsWithAmountBinding,
                options: Self.startOptions
            )
        }
        .frame(minHeight: 52)
    }

    func row(_ item: SetupItem) -> some View {
        HStack(spacing: 12) {
            Image(systemName: item.systemImage)
                .sansFont(.body, weight: .light)
                .foregroundStyle(Palette.accent)
                .frame(width: 22)

            Text(item.title)
                .textFont(.subheadline)
                .foregroundStyle(Palette.text)
                .lineLimit(1)

            Spacer()

            if model.isDone(item) {
                Image(systemName: "checkmark")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Palette.accent)
                    .transition(.scale.combined(with: .opacity))
            }

            Image(systemName: "chevron.right")
                .font(.footnote)
                .foregroundStyle(Palette.hint)
        }
        .frame(minHeight: 48)
        .contentShape(.rect)
        .animation(.snappy, value: model.isDone(item))
    }
}

private extension SetupList {
    static let startOptions: [CapsulePicker<Bool>.Option] = [
        .init("する", value: true),
        .init("しない", value: false)
    ]

    var startsWithAmountBinding: Binding<Bool> {
        Binding {
            model.startsWithAmount
        } set: { starts in
            Task {
                await model.setStartsWithAmount(starts)
            }
        }
    }
}
