#if DEBUG
import Core
import SwiftUI

public struct DebugMenu: View {
    @State private var model = DebugMenuModel()
    @State private var sheet: Sheet?

    @Environment(\.dismiss) private var dismiss

    public init() {}

    public var body: some View {
        NavigationStack {
            List {
                Section("画面") {
                    Button("メイン画面") {
                        sheet = .main
                    }

                    Button("入力シート（新規）") {
                        sheet = .newEntry
                    }

                    Button("入力シート（編集）") {
                        sheet = .editEntry
                    }
                }
                .disabled(model.database == nil)

                if let errorMessage = model.errorMessage {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                }
            }
            .navigationTitle("デバッグ")
            .toolbar {
                Button("閉じる") {
                    dismiss()
                }
            }
        }
        .sheet(item: $sheet) { sheet in
            screen(for: sheet)
        }
        .task {
            await model.prepare()
        }
    }
}

private extension DebugMenu {
    enum Sheet: Identifiable {
        case main
        case newEntry
        case editEntry

        var id: Self {
            self
        }
    }

    @ViewBuilder
    func screen(for sheet: Sheet) -> some View {
        if let database = model.database {
            switch sheet {
            case .main:
                MainView(database: database)
            case .newEntry, .editEntry:
                let editing = sheet == .editEntry ? model.sampleEntryId : nil
                let today = LocalDate(Date(), in: .current)

                EntrySheet(
                    model: EntryModel(
                        database: database,
                        editing: editing,
                        date: today
                    )
                )
            }
        }
    }
}

#Preview {
    DebugMenu()
}
#endif
