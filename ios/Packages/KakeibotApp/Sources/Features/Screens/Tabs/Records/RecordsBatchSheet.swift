import Core
import DesignSystem
import SwiftUI

struct RecordsBatchSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.themeStyle.corner) private var corner

    let model: RecordsModel
    let target: Target
    let count: Int
    let onChoose: (EntryBatchChange) -> Void

    var body: some View {
        FittedSheet {
            VStack(spacing: 20) {
                header

                VStack(spacing: 8) {
                    switch target {
                    case let .category(type):
                        ForEach(model.batchCategories(for: type)) { category in
                            row(
                                category.name,
                                icon: model.icon(for: category),
                                change: .category(category.id)
                            )
                        }
                    case .wallet:
                        ForEach(model.batchWallets) { wallet in
                            row(
                                wallet.name,
                                icon: model.icon(for: wallet),
                                change: .wallet(wallet.id)
                            )
                        }
                    }
                }
                .sharesTextScale(id: names)
            }
        }
    }
}

extension RecordsBatchSheet {
    enum Target: Hashable, Identifiable {
        case category(Entry.Kind)
        case wallet

        var id: Self {
            self
        }
    }
}

private extension RecordsBatchSheet {
    var header: some View {
        HStack {
            RingButton(systemImage: "xmark") {
                dismiss()
            }

            Spacer()

            SheetTitle(title)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Spacer()

            Color.clear
                .frame(width: 44, height: 44)
        }
    }

    func row(
        _ name: String,
        icon: Icon?,
        change: EntryBatchChange
    ) -> some View {
        Button {
            onChoose(change)
            dismiss()
        } label: {
            HStack(spacing: 12) {
                IconBadge(icon, size: 36)

                Text(name)
                    .textFont(.subheadline)
                    .foregroundStyle(Palette.text)
                    .sharedTextScale()

                Spacer(minLength: 8)
            }
            .padding(.horizontal, 16)
            .frame(minHeight: 56)
            .background(Palette.panel, in: shape)
            .overlay {
                shape
                    .stroke(Palette.line, lineWidth: 1)
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }
}

private extension RecordsBatchSheet {
    var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: corner.radius(16))
    }

    var names: [String] {
        switch target {
        case let .category(type): model.batchCategories(for: type).map(\.name)
        case .wallet: model.batchWallets.map(\.name)
        }
    }

    var title: String {
        switch target {
        case .category: "\(count) 件のカテゴリを変える"
        case .wallet: "\(count) 件の口座を変える"
        }
    }
}
