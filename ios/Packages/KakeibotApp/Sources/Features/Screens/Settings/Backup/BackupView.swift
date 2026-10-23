import DesignSystem
import Store
import SwiftUI
import UniformTypeIdentifiers

public struct BackupView: View {
    @State private var model: BackupModel
    @State private var isExporting = false
    @State private var isImporting = false
    @State private var isConfirmingRestore = false

    public init(model: BackupModel) {
        _model = State(initialValue: model)
    }

    public var body: some View {
        VStack(spacing: 16) {
            SettingsBackHeader("バックアップ")

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        note(
                            "doc.on.doc",
                            "すべての記録と設定を 1 つのファイルにします"
                        )

                        note(
                            "iphone.and.arrow.forward",
                            "機種変更の前に書き出すと、新しい端末で戻せます"
                        )
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .card()

                    VStack(spacing: 0) {
                        Button {
                            exportFile(.json)
                        } label: {
                            action(
                                "書き出す",
                                systemImage: "square.and.arrow.up",
                                detail: "ファイルに保存します"
                            )
                        }

                        Hairline()

                        Button {
                            exportFile(.csv)
                        } label: {
                            action(
                                "表計算用に書き出す",
                                systemImage: "tablecells",
                                detail: "記録を CSV で保存します。読み込みには使えません"
                            )
                        }

                        Hairline()

                        Button {
                            importFile()
                        } label: {
                            action(
                                "読み込む",
                                systemImage: "square.and.arrow.down",
                                detail: "いまのデータと置き換えます"
                            )
                        }
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 16)
                    .card()

                    if let message = model.doneMessage {
                        Label(message, systemImage: "checkmark.circle")
                            .textFont(.footnote)
                            .foregroundStyle(Palette.accent)
                            .padding(.leading, 8)
                            .transition(.opacity)
                    }
                }
                .padding(.vertical, 8)
            }
            .scrollIndicators(.hidden)
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 8)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .errorBanner(model.errorNotice) {
            model.errorNotice.clear()
        }
        .background {
            Rectangle()
                .fill(Palette.background)
                .ignoresSafeArea()
        }
        .toolbar(.hidden, for: .navigationBar)
        .animation(.snappy, value: model.doneMessage)
        .fileExporter(
            isPresented: $isExporting,
            document: document,
            contentType: exportType,
            defaultFilename: model.file?.name
        ) { result in
            model.finishExport(result)
        }
        .fileImporter(
            isPresented: $isImporting,
            allowedContentTypes: [.json]
        ) { result in
            isConfirmingRestore = model.read(result)
        }
        .confirmation(
            isPresented: $isConfirmingRestore,
            systemImage: "arrow.triangle.2.circlepath",
            title: "データを置き換えますか",
            message: model.pendingSummary ?? "",
            keepTitle: "やめる",
            confirmTitle: "置き換える"
        ) {
            model.cancelRestore()
        } onConfirm: {
            Task {
                await model.restore()
            }
        }
    }
}

private extension BackupView {
    func note(
        _ systemImage: String,
        _ text: String
    ) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Image(systemName: systemImage)
                .font(.caption.weight(.medium))
                .foregroundStyle(Palette.accent)
                .frame(width: 22)

            Text(text)
                .textFont(.footnote)
                .foregroundStyle(Palette.text)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    func action(
        _ title: String,
        systemImage: String,
        detail: String
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .sansFont(.body, weight: .light)
                .foregroundStyle(Palette.accent)
                .frame(width: 22)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .textFont(.subheadline)
                    .foregroundStyle(Palette.text)

                Text(detail)
                    .textFont(.caption2)
                    .foregroundStyle(Palette.subtext)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.footnote)
                .foregroundStyle(Palette.hint)
        }
        .frame(minHeight: 58)
        .contentShape(.rect)
    }
}

private extension BackupView {
    var document: BackupDocument? {
        model.file.map { BackupDocument(data: $0.data) }
    }

    var exportType: UTType {
        model.file?.kind == .csv ? .commaSeparatedText : .json
    }

    func exportFile(_ kind: BackupModel.FileKind) {
        guard !model.isWorking else {
            return
        }

        Task {
            isExporting = await model.makeFile(kind, at: Date())
        }
    }

    func importFile() {
        guard !model.isWorking else {
            return
        }

        isImporting = true
    }
}

#Preview {
    if let database = try? AppDatabase.inMemory() {
        NavigationStack {
            BackupView(model: BackupModel(database: database))
        }
    }
}
