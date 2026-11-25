import DesignSystem
import FeatureModels
import SwiftUI
import UniformTypeIdentifiers

public struct BackupView: View {
    @State private var model: BackupModel
    @State private var isExporting = false
    @State private var isImporting = false
    @State private var isConfirmingRestore = false
    @State private var pressed: String?

    public init(model: BackupModel) {
        _model = State(initialValue: model)
    }

    public var body: some View {
        VStack(spacing: SettingsSpacing.header) {
            SettingsBackHeader("バックアップ", hint: hint)

            BackupIntroCard(hint: hint)

            ScrollView {
                VStack(alignment: .leading, spacing: SettingsSpacing.section) {
                    VStack(alignment: .leading, spacing: 8) {
                        SettingsSectionTitle("残す")

                        VStack(spacing: 0) {
                            actionButton(
                                "書き出す",
                                systemImage: "square.and.arrow.up",
                                detail: "すべての記録と設定を保存します"
                            ) {
                                exportFile(.json)
                            }

                            Hairline()

                            actionButton(
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

                    VStack(alignment: .leading, spacing: 8) {
                        SettingsSectionTitle("戻す")

                        VStack(spacing: 0) {
                            actionButton(
                                "読み込む",
                                systemImage: "square.and.arrow.down",
                                detail: "ファイルから戻します"
                            ) {
                                importFile()
                            }

                            ForEach(model.input.previous) { item in
                                Hairline()

                                actionButton(
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

                    if let message = model.state.doneMessage {
                        Label(message, systemImage: "checkmark.circle")
                            .textFont(.footnote)
                            .foregroundStyle(Palette.accent)
                            .padding(.leading, 8)
                            .transition(.opacity)
                    }
                }
                .disabled(model.state.isWorking)
                .buttonStyle(.plain)
                .padding(.vertical, 8)
            }
            .scrollIndicators(.hidden)
        }
        .padding(.horizontal, SettingsSpacing.side)
        .padding(.top, SettingsSpacing.top)
        .padding(.bottom, 8)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .errorBanner(Bindable(model.state).errorNotice)
        .backdrop()
        .toolbar(.hidden, for: .navigationBar)
        .task {
            await model.observeSync()
        }
        .task {
            await model.loadPrevious()
        }
        .animation(.snappy, value: model.state.doneMessage)
        .onChange(of: model.state.isWorking) { _, isWorking in
            if !isWorking {
                pressed = nil
            }
        }
        .fileExporter(
            isPresented: $isExporting,
            document: document,
            contentType: exportType,
            defaultFilename: model.state.file?.name
        ) { result in
            Task {
                await model.finishExport(result)
            }
        }
        .fileImporter(
            isPresented: $isImporting,
            allowedContentTypes: [.json]
        ) { result in
            Task {
                isConfirmingRestore = await model.read(result)
            }
        }
        .confirmation(
            isPresented: $isConfirmingRestore,
            systemImage: "arrow.triangle.2.circlepath",
            title: "データを置き換えますか",
            message: model.output.pendingSummary ?? "",
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
    func actionButton(
        _ title: String,
        systemImage: String,
        detail: String,
        action: @escaping () -> Void
    ) -> some View {
        let isWorking = model.state.isWorking && pressed == title

        return Button {
            pressed = title
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

    func exportFile(_ kind: BackupModel.FileKind) {
        Task {
            isExporting = await model.makeFile(kind)
        }
    }

    func importFile() {
        isImporting = true
    }

    func restorePrevious(_ item: BackupModel.Previous) {
        Task {
            isConfirmingRestore = await model.readPrevious(item)
        }
    }
}

private extension BackupView {
    var hint: SettingsFold {
        SettingsFold(\.hint, in: model)
    }
}

#Preview {
    if let parts = ScreenParts.preview() {
        NavigationStack {
            BackupView(model: BackupModel(parts: parts))
        }
    }
}
