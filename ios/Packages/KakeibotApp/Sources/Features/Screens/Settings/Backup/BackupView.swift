import DesignSystem
import FeatureModels
import SwiftUI
import UniformTypeIdentifiers

public struct BackupView: View {
    @State private var model: BackupModel

    public init(model: BackupModel) {
        _model = State(initialValue: model)
    }

    public var body: some View {
        VStack(spacing: SettingsSpacing.header) {
            SettingsBackHeader("バックアップ", hint: hint)

            BackupIntroCard(hint: hint)

            content
        }
        .padding(.horizontal, SettingsSpacing.side)
        .padding(.top, SettingsSpacing.top)
        .padding(.bottom, 8)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .errorBanner(model.state.errorNotice)
        .backdrop()
        .toolbar(.hidden, for: .navigationBar)
        .task {
            await model.observeSync()
        }
        .task {
            await model.loadPrevious()
        }
        .animation(.snappy, value: model.state.doneMessage)
        .fileExporter(
            isPresented: Bindable(model.state).presented.dialog[.exporter],
            document: document,
            contentType: exportType,
            defaultFilename: model.state.file?.name
        ) { result in
            model.perform {
                await $0.finishExport(result)
            }
        }
        .fileImporter(
            isPresented: Bindable(model.state).presented.dialog[.importer],
            allowedContentTypes: [.json]
        ) { result in
            model.perform {
                await $0.read(result)
            }
        }
        .confirmation(
            isPresented: Bindable(model.state).presented.dialog[.restore],
            systemImage: "arrow.triangle.2.circlepath",
            title: "データを置き換えますか",
            message: model.output.pendingSummary ?? "",
            keepTitle: "やめる",
            confirmTitle: "置き換える"
        ) {
            model.cancelRestore()
        } onConfirm: {
            model.perform {
                await $0.restore()
            }
        }
    }
}

private extension BackupView {
    var content: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: SettingsSpacing.section) {
                saveSection

                restoreSection

                if let message = model.state.doneMessage {
                    Label(message, systemImage: "checkmark.circle")
                        .textFont(.footnote)
                        .foregroundStyle(Palette.accent)
                        .padding(.leading, 8)
                        .transition(.opacity)
                }
            }
            .disabled(model.state.task.isRunning)
            .buttonStyle(.plain)
            .padding(.vertical, 8)
        }
        .scrollIndicators(.hidden)
    }

    var saveSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            SettingsSectionTitle("残す")

            VStack(spacing: 0) {
                actionButton(
                    .export(.json),
                    "書き出す",
                    systemImage: "square.and.arrow.up",
                    detail: "すべての記録と設定を保存します"
                ) {
                    exportFile(.json)
                }

                Hairline()

                actionButton(
                    .export(.csv),
                    "表計算用に書き出す",
                    systemImage: "tablecells",
                    detail: "CSV で保存します。読み込めません"
                ) {
                    exportFile(.csv)
                }
            }
            .padding(.horizontal, 16)
            .card()
        }
    }

    var restoreSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            SettingsSectionTitle("戻す")

            VStack(spacing: 0) {
                actionButton(
                    .importFile,
                    "読み込む",
                    systemImage: "square.and.arrow.down",
                    detail: "ファイルから戻します"
                ) {
                    importFile()
                }

                ForEach(model.input.previous) { item in
                    Hairline()

                    actionButton(
                        .previous(item),
                        model.output.previousTitle(of: item),
                        systemImage: "arrow.uturn.backward",
                        detail: "読み込む前に退避したデータです"
                    ) {
                        restorePrevious(item)
                    }
                }
            }
            .disabled(model.input.isSyncActive)
            .opacity(restoreOpacity)
            .padding(.horizontal, 16)
            .card()

            SettingsCaption(
                restoreNote,
                kind: model.input.isSyncActive
                    ? .info
                    : .caution
            )
        }
    }

    func actionButton(
        _ row: BackupModel.Row,
        _ title: String,
        systemImage: String,
        detail: String,
        action: @escaping () -> Void
    ) -> some View {
        let isWorking = model.state.task.isRunning && model.state.pressed == row

        return Button {
            model.state.press(row)
            action()
        } label: {
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
                .lineLimit(1)
                .minimumScaleFactor(0.8)

                Spacer()

                if isWorking {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    DisclosureMark()
                }
            }
            .frame(minHeight: 58)
            .contentShape(.rect)
        }
    }
}

private extension BackupView {
    var restoreOpacity: Double {
        model.input.isSyncActive ? 0.5 : 1
    }

    var restoreNote: String {
        model.input.isSyncActive ? "同期と共有をやめると、読み込めます。" : "読み込むと、いまのデータと置き換わります。"
    }

    var document: BackupDocument? {
        model.state.file.map { BackupDocument(data: $0.data) }
    }

    var exportType: UTType {
        model.state.file?.kind == .csv ? .commaSeparatedText : .json
    }

    var hint: SettingsFold {
        SettingsFold(\.hint, in: model)
    }

    func exportFile(_ kind: BackupModel.FileKind) {
        model.perform {
            await $0.makeFile(kind)
        }
    }

    func importFile() {
        model.state.presented.dialog.show(.importer)
    }

    func restorePrevious(_ item: BackupModel.Previous) {
        model.perform {
            await $0.readPrevious(item)
        }
    }
}

#Preview {
    if let parts = ScreenParts.preview() {
        NavigationStack {
            BackupView(model: BackupModel(parts: parts))
        }
    }
}
