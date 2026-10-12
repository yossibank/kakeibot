import Core
import DesignSystem
import Store
import SwiftUI

@MainActor
public struct EntrySheet {
    @State private var model: EntryModel
    @State private var isConfirmingDelete = false

    @Environment(\.dismiss) private var dismiss

    public init(model: EntryModel) {
        _model = State(initialValue: model)
    }
}

private extension EntrySheet {
    var categoryGrid: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 72))], spacing: 12) {
            ForEach(model.categories) { category in
                categoryButton(category)
            }
        }
    }

    var details: some View {
        VStack(spacing: 12) {
            LabeledContent("財布") {
                Picker("財布", selection: $model.walletId) {
                    ForEach(model.wallets) { wallet in
                        Text(wallet.name).tag(Optional(wallet.id))
                    }
                }
                .labelsHidden()
            }

            DatePicker("日付", selection: dayBinding, displayedComponents: .date)

            TextField("メモ", text: $model.memo)
                .textFieldStyle(.roundedBorder)
        }
    }

    @ToolbarContentBuilder
    var toolbar: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button("キャンセル") { dismiss() }
        }

        ToolbarItem(placement: .confirmationAction) {
            Button("保存") {
                Task { await save() }
            }
            .disabled(!model.canSave)
        }
    }

    func categoryButton(_ category: EntryCategory) -> some View {
        let isSelected = model.categoryId == category.id

        return Button {
            model.categoryId = category.id
        } label: {
            VStack(spacing: 4) {
                IconBadge(model.icon(for: category), size: 44)

                Text(category.name)
                    .font(.caption)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, minHeight: 72)
            .background(
                isSelected ? Color.accentColor.opacity(0.15) : Color.clear,
                in: RoundedRectangle(cornerRadius: 12, style: .continuous)
            )
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

private extension EntrySheet {
    var typeBinding: Binding<Entry.Kind> {
        Binding(
            get: { model.type },
            set: { model.select($0) }
        )
    }

    var dayBinding: Binding<Date> {
        Binding(
            get: { Self.startOfDay(model.date) },
            set: { model.date = LocalDate($0, in: .current) }
        )
    }

    static func startOfDay(_ date: LocalDate) -> Date {
        let components = DateComponents(year: date.year, month: date.month, day: date.day)
        return Calendar.current.date(from: components) ?? Date()
    }

    func save() async {
        if await model.save() {
            dismiss()
        }
    }

    func delete() async {
        if await model.delete() {
            dismiss()
        }
    }
}

extension EntrySheet: View {
    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    Picker("種類", selection: typeBinding) {
                        Text("支出").tag(Entry.Kind.expense)
                        Text("収入").tag(Entry.Kind.income)
                    }
                    .pickerStyle(.segmented)

                    AmountText(model.amount, type: model.type)
                        .font(.system(size: 44, weight: .bold))
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .accessibilityLabel("金額")
                        .accessibilityValue(AmountText.text(model.amount))

                    categoryGrid
                    details

                    if let errorMessage = model.errorMessage {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                    }

                    if model.isEditing {
                        Button("この記録を消す", role: .destructive) {
                            isConfirmingDelete = true
                        }
                    }
                }
                .padding()
            }
            .safeAreaInset(edge: .bottom) {
                Keypad { model.press($0) }
                    .padding()
                    .background(.bar)
            }
            .navigationTitle(model.isEditing ? "記録を直す" : "記録する")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbar }
            .confirmationDialog(
                "この記録を消しますか",
                isPresented: $isConfirmingDelete,
                titleVisibility: .visible
            ) {
                Button("消す", role: .destructive) {
                    Task { await delete() }
                }
            }
        }
        .task { await model.load() }
    }
}

#if DEBUG
    #Preview {
        let database = try? AppDatabase.inMemory()
        let today = LocalDate(Date(), in: .current)

        if let database {
            let _ = try? database.insertDefaultsIfEmpty(at: Date())
            EntrySheet(model: EntryModel(database: database, date: today))
        }
    }
#endif
