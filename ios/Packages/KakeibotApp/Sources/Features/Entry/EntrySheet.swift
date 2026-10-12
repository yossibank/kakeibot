import Core
import DesignSystem
import Store
import SwiftUI

public struct EntrySheet: View {
    @State private var model: EntryModel
    @State private var isConfirmingDelete = false
    @State private var isEditingMemo = false

    @Environment(\.dismiss) private var dismiss

    public init(model: EntryModel) {
        _model = State(initialValue: model)
    }

    public var body: some View {
        VStack(spacing: 14) {
            header
            dial
            chips
            categoryGrid

            if let errorMessage = model.errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(Palette.champagne)
            }

            if model.isEditing {
                Button("この記録を消す", role: .destructive) {
                    isConfirmingDelete = true
                }
                .font(.footnote)
            }

            Spacer(minLength: 0)

            Keypad { model.press($0) }
        }
        .padding(.horizontal, 20)
        .padding(.top, 18)
        .background(Palette.night.ignoresSafeArea())
        .preferredColorScheme(.dark)
        .alert("メモ", isPresented: $isEditingMemo) {
            TextField("メモ", text: $model.memo)
            Button("OK") {}
        }
        .confirmationDialog(
            "この記録を消しますか",
            isPresented: $isConfirmingDelete,
            titleVisibility: .visible
        ) {
            Button("消す", role: .destructive) {
                Task { await delete() }
            }
        }
        .task { await model.load() }
    }
}

private extension EntrySheet {
    var header: some View {
        HStack {
            RingButton("キャンセル", systemImage: "xmark") {
                dismiss()
            }

            Spacer()

            CapsulePicker(selection: typeBinding, options: Self.typeOptions)

            Spacer()

            RingButton("保存", systemImage: "checkmark", isProminent: true) {
                Task { await save() }
            }
            .disabled(!model.canSave)
        }
        .frame(minHeight: 44)
    }

    var dial: some View {
        ZStack {
            Circle()
                .stroke(Palette.gold.opacity(0.6), lineWidth: 1)
                .frame(width: 240, height: 240)

            DialTicks(count: 60, length: 9)
                .stroke(Palette.gold.opacity(0.85), lineWidth: 1)
                .frame(width: 214, height: 214)

            DialTicks(count: 12, length: 14)
                .stroke(Palette.champagne, lineWidth: 1.5)
                .frame(width: 214, height: 214)

            VStack(spacing: 4) {
                Text(model.type == .income ? "収入" : "支出")
                    .font(.system(.caption, design: .serif))
                    .tracking(4)
                    .foregroundStyle(Palette.gold)

                Text(AmountText.text(model.amount))
                    .font(.system(size: 54, weight: .semibold, design: .serif))
                    .foregroundStyle(Palette.champagne)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                    .frame(maxWidth: 180)
            }
        }
        .frame(height: 250)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("金額")
        .accessibilityValue(AmountText.text(model.amount))
    }

    var chips: some View {
        HStack(spacing: 8) {
            Menu {
                Picker("財布", selection: $model.walletId) {
                    ForEach(model.wallets) { wallet in
                        Text(wallet.name).tag(Optional(wallet.id))
                    }
                }
            } label: {
                Chip(model.walletName, systemImage: "wallet.bifold")
            }

            DatePicker("日付", selection: dayBinding, displayedComponents: .date)
                .labelsHidden()
                .tint(Palette.gold)

            Button {
                isEditingMemo = true
            } label: {
                Chip(model.memo.isEmpty ? "メモ" : model.memo, systemImage: "square.and.pencil")
            }
        }
    }

    var categoryGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 6) {
            ForEach(model.categories) { category in
                categoryButton(category)
            }
        }
    }

    func categoryButton(_ category: EntryCategory) -> some View {
        let isSelected = model.categoryId == category.id

        return Button {
            model.categoryId = category.id
        } label: {
            VStack(spacing: 5) {
                IconImage(model.icon(for: category), size: 20)

                Text(category.name)
                    .font(.system(size: 10))
                    .lineLimit(1)
                    .padding(.bottom, 3)
                    .overlay(alignment: .bottom) {
                        Rectangle()
                            .fill(isSelected ? Palette.gold : Color.clear)
                            .frame(height: 1)
                    }
            }
            .foregroundStyle(isSelected ? Palette.champagne : Palette.dusk)
            .frame(maxWidth: .infinity, minHeight: 56)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

private extension EntrySheet {
    static let typeOptions: [CapsulePicker<Entry.Kind>.Option] = [
        .init("支出", value: .expense),
        .init("収入", value: .income)
    ]

    var typeBinding: Binding<Entry.Kind> {
        Binding(
            get: { model.type },
            set: { model.select($0) }
        )
    }

    var dayBinding: Binding<Date> {
        Binding(
            get: { model.date.startOfDay(in: .current) },
            set: { model.date = LocalDate($0, in: .current) }
        )
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

#Preview {
    let database = try? AppDatabase.inMemory()
    let today = LocalDate(Date(), in: .current)

    if let database {
        let _ = try? database.insertDefaultsIfEmpty(at: Date())
        EntrySheet(model: EntryModel(database: database, date: today))
    }
}
