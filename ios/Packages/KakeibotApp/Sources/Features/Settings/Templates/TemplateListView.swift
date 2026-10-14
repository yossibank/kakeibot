import Core
import DesignSystem
import Store
import SwiftUI

public struct TemplateListView: View {
    @State private var model: TemplateListModel
    @State private var sheet: Sheet?

    @Environment(\.dismiss) private var dismiss

    private let database: AppDatabase

    public init(database: AppDatabase) {
        _model = State(initialValue: TemplateListModel(database: database))
        self.database = database
    }

    public var body: some View {
        VStack(spacing: 14) {
            header

            Text(hint)
                .font(.caption)
                .foregroundStyle(Palette.mist)
                .multilineTextAlignment(.center)

            List {
                ForEach(model.templates) { template in
                    row(template)
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                }
                .onMove { source, destination in
                    Task {
                        await model.move(from: source, to: destination)
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .environment(\.defaultMinListRowHeight, 0)

            if let errorMessage = model.errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(Palette.rose)
            }

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
            TemplateEditSheet(model: editModel(for: sheet))
        }
        .task {
            await model.observe()
        }
    }
}

private extension TemplateListView {
    var header: some View {
        HStack {
            RingButton(systemImage: "chevron.left") {
                dismiss()
            }

            Spacer()

            Text("テンプレート")
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
            Label("テンプレートを追加", systemImage: "plus")
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

    func row(_ template: EntryTemplate) -> some View {
        Button {
            sheet = .edit(template.id)
        } label: {
            HStack(spacing: 12) {
                IconImage(model.icon(for: template), size: 17)
                    .foregroundStyle(Palette.gold)
                    .frame(width: 38, height: 38)
                    .overlay {
                        Circle()
                            .stroke(Palette.gold.opacity(0.35), lineWidth: 1)
                    }

                VStack(alignment: .leading, spacing: 3) {
                    Text(template.name)
                        .font(.subheadline)
                        .foregroundStyle(Palette.ink)

                    Text(model.detail(for: template))
                        .font(.caption2)
                        .foregroundStyle(Palette.mist)
                        .lineLimit(1)
                }

                Spacer(minLength: 8)

                Text(model.amountText(for: template))
                    .font(.system(size: 15, design: .serif))
                    .foregroundStyle(amountColor(for: template))
            }
            .padding(.horizontal, 14)
            .frame(minHeight: 62)
            .background(Self.rowFill, in: .rect(cornerRadius: 18))
            .overlay {
                RoundedRectangle(cornerRadius: 18)
                    .stroke(Palette.gold.opacity(0.18), lineWidth: 1)
            }
            .padding(.vertical, 4)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }
}

private extension TemplateListView {
    enum Sheet: Hashable, Identifiable {
        case new
        case edit(EntryTemplate.ID)

        var id: Self {
            self
        }
    }

    static let dash = StrokeStyle(lineWidth: 1, dash: [4, 3])

    static var rowFill: LinearGradient {
        LinearGradient(
            colors: [Palette.cardTop, Palette.cardBottom],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    var hint: String {
        if model.templates.isEmpty {
            "よく使う入力を残しておくと、ホームと入力シートから 1 回で入れられる"
        } else {
            "長押しで並べ替え。上から順にホームと入力シートに出る"
        }
    }

    func amountColor(for template: EntryTemplate) -> Color {
        template.amount == nil ? Palette.mist : Palette.champagne
    }

    func editModel(for sheet: Sheet) -> TemplateEditModel {
        switch sheet {
        case .new:
            TemplateEditModel(database: database)
        case let .edit(id):
            TemplateEditModel(database: database, editing: id)
        }
    }
}

#Preview {
    if let database = try? AppDatabase.inMemory() {
        let _ = try? database.insertDefaultsIfEmpty(at: Date())

        NavigationStack {
            TemplateListView(database: database)
        }
    }
}
