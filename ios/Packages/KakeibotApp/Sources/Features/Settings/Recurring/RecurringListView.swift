import Core
import DesignSystem
import Store
import SwiftUI

public struct RecurringListView: View {
    @State private var model: RecurringListModel
    @State private var sheet: Sheet?

    @Environment(\.dismiss) private var dismiss

    public init(model: RecurringListModel) {
        _model = State(initialValue: model)
    }

    public var body: some View {
        VStack(spacing: 14) {
            header

            Text("決まった日に、記録をひとりでに入れます")
                .font(.caption)
                .foregroundStyle(Palette.mist)

            ScrollView {
                VStack(spacing: 10) {
                    ForEach(model.rows) { row in
                        rowButton(row)
                    }

                    if model.rows.isEmpty {
                        Text("家賃や給料などを足すと、ここに並びます")
                            .font(.footnote)
                            .foregroundStyle(Palette.mist)
                            .padding(.vertical, 40)
                    }

                    if let errorMessage = model.errorMessage {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(Palette.rose)
                    }
                }
                .padding(.vertical, 8)
            }
            .scrollIndicators(.hidden)

            addButton
        }
        .padding(.horizontal, 18)
        .padding(.top, 16)
        .padding(.bottom, 8)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background {
            Rectangle()
                .fill(Palette.night)
                .ignoresSafeArea()
        }
        .toolbar(.hidden, for: .navigationBar)
        .preferredColorScheme(.dark)
        .sheet(item: $sheet) { sheet in
            RecurringEditSheet(model: model.editModel(for: sheet.editingId))
        }
        .task {
            await model.observe()
        }
    }
}

private extension RecurringListView {
    var header: some View {
        HStack {
            RingButton(systemImage: "chevron.left") {
                dismiss()
            }

            Spacer()

            Text("固定費")
                .font(.system(size: 16, design: .serif))
                .tracking(4)
                .foregroundStyle(Palette.gold)

            Spacer()

            Color.clear
                .frame(width: 44, height: 44)
        }
    }

    var addButton: some View {
        Button {
            sheet = .new
        } label: {
            Label("固定費を追加", systemImage: "plus")
                .font(.subheadline)
                .foregroundStyle(Palette.gold)
                .frame(maxWidth: .infinity, minHeight: 50)
                .background(Palette.gold.opacity(0.06), in: Capsule())
                .overlay {
                    Capsule()
                        .stroke(Palette.gold.opacity(0.55), style: Self.dash)
                }
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    func rowButton(_ row: RecurringListModel.Row) -> some View {
        Button {
            sheet = .edit(row.id)
        } label: {
            HStack(spacing: 12) {
                IconBadge(row.icon, size: 38)

                VStack(alignment: .leading, spacing: 3) {
                    Text(row.title)
                        .font(.subheadline)
                        .foregroundStyle(Palette.ink)
                        .lineLimit(1)

                    Text(row.detail)
                        .font(.caption)
                        .foregroundStyle(Palette.mist)
                        .lineLimit(1)
                }

                Spacer(minLength: 8)

                VStack(alignment: .trailing, spacing: 3) {
                    AmountText(row.amount, type: row.type)

                    Text(Self.nextText(row.next))
                        .font(.caption2)
                        .foregroundStyle(Palette.mist)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .card()
    }
}

private extension RecurringListView {
    enum Sheet: Identifiable {
        case new
        case edit(Recurring.ID)
    }

    static let dash = StrokeStyle(lineWidth: 1, dash: [5, 4])

    static func nextText(_ date: LocalDate?) -> String {
        guard let date else {
            return "終わりました"
        }

        return "次は \(date.month)/\(date.day)"
    }
}

private extension RecurringListView.Sheet {
    var id: String {
        switch self {
        case .new: "new"
        case let .edit(id): id.description
        }
    }

    var editingId: Recurring.ID? {
        switch self {
        case .new: nil
        case let .edit(id): id
        }
    }
}
