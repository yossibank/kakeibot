#if DEBUG
import Core
import DesignSystem
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
                    Button("入力シート（新規）") {
                        sheet = .newEntry
                    }

                    Button("入力シート（編集）") {
                        sheet = .editEntry
                    }
                }
                .disabled(model.database == nil)

                Section("部品") {
                    ForEach(DebugComponent.allCases) { component in
                        NavigationLink(component.title) {
                            component.page
                                .navigationTitle(component.title)
                                .navigationBarTitleDisplayMode(.inline)
                        }
                    }
                }

                if let errorMessage = model.errorMessage {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                }
            }
            .navigationTitle("デバッグ")
            .toolbar {
                Button("閉じる") { dismiss() }
            }
        }
        .sheet(item: $sheet) { sheet in
            entrySheet(for: sheet)
        }
        .task { await model.prepare() }
    }
}

private extension DebugMenu {
    enum Sheet: Identifiable {
        case newEntry
        case editEntry

        var id: Self {
            self
        }
    }

    @ViewBuilder
    func entrySheet(for sheet: Sheet) -> some View {
        if let database = model.database {
            let editing = sheet == .editEntry ? model.sampleEntryId : nil
            let today = LocalDate(Date(), in: .current)
            let entryModel = EntryModel(database: database, editing: editing, date: today)

            EntrySheet(model: entryModel)
        }
    }
}

#Preview {
    DebugMenu()
}
#endif
