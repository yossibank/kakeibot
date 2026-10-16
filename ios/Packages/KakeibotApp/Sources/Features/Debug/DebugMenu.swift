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

                    Button("起動の動き") {
                        sheet = .launch
                    }

                    Button("入力シート（新規）") {
                        sheet = .newEntry
                    }

                    Button("入力シート（編集）") {
                        sheet = .editEntry
                    }

                    Button("カテゴリ") {
                        sheet = .categories
                    }

                    Button("カテゴリの編集（新規）") {
                        sheet = .newCategory
                    }

                    Button("テンプレート") {
                        sheet = .templates
                    }

                    Button("テンプレートの編集（新規）") {
                        sheet = .newTemplate
                    }

                    Button("口座") {
                        sheet = .wallets
                    }

                    Button("口座の編集（新規）") {
                        sheet = .newWallet
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
        case launch
        case newEntry
        case editEntry
        case categories
        case newCategory
        case templates
        case newTemplate
        case wallets
        case newWallet

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
            case .launch:
                MainView(database: database)
                    .overlay {
                        LaunchView(isReady: true) {}
                    }
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
            case .categories:
                NavigationStack {
                    CategoryListView(database: database)
                }
            case .newCategory:
                CategoryEditSheet(
                    model: CategoryEditModel(
                        database: database,
                        kind: .expense
                    )
                )
            case .templates:
                NavigationStack {
                    TemplateListView(database: database)
                }
            case .newTemplate:
                TemplateEditSheet(
                    model: TemplateEditModel(
                        database: database,
                        type: .expense
                    )
                )
            case .wallets:
                NavigationStack {
                    WalletListView(database: database)
                }
            case .newWallet:
                WalletEditSheet(model: WalletEditModel(database: database))
            }
        }
    }
}

#Preview {
    DebugMenu()
}
#endif
