#if DEBUG
    import Store
    import SwiftUI

    @MainActor
    struct DebugView {
        @State private var model: DebugModel

        init(database: AppDatabase) {
            _model = State(initialValue: DebugModel(database: database))
        }
    }

    extension DebugView: View {
        var body: some View {
            NavigationStack {
                List {
                    LabeledContent("記録の件数", value: model.entryCount.formatted())

                    Button("1,000 件書く") {
                        Task { await model.writeBatch() }
                    }

                    Button(model.isWriting ? "書き続けるのを止める" : "0.2 秒ごとに 100 件書き続ける") {
                        model.toggleWriting()
                    }

                    if let lastError = model.lastError {
                        Text(lastError)
                            .foregroundStyle(.red)
                    }
                }
                .navigationTitle("DB の確認")
            }
            .task { await model.refresh() }
        }
    }
#endif
