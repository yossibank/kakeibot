import DesignSystem
import Store
import SwiftUI

public struct SyncView: View {
    @State private var model: SyncModel

    public init(model: SyncModel) {
        _model = State(initialValue: model)
    }

    public var body: some View {
        VStack(spacing: 16) {
            SettingsBackHeader("iCloud 同期")

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        note(
                            "arrow.triangle.2.circlepath",
                            "記録と設定を、同じ iCloud の端末どうしでそろえます"
                        )

                        note(
                            "lock",
                            "データは iCloud に暗号化して置きます"
                        )
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .card()

                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 12) {
                            Text("同期する")
                                .textFont(.subheadline)
                                .foregroundStyle(Palette.text)

                            Spacer(minLength: 0)

                            CapsulePicker(selection: onBinding, options: Self.onOptions)
                        }
                        .frame(minHeight: 58)
                        .padding(.horizontal, 16)
                        .card()
                        .disabled(model.isWorking || !canChange)

                        if model.isOn,
                           let count = model.pendingCount {
                            HStack(spacing: 8) {
                                if count > 0 {
                                    ProgressView()
                                        .controlSize(.mini)
                                } else {
                                    Image(systemName: "checkmark.circle")
                                        .foregroundStyle(Palette.accent)
                                }

                                Text(pendingText(count))
                            }
                            .textFont(.footnote)
                            .foregroundStyle(Palette.subtext)
                            .padding(.leading, 8)
                        }

                        Text(footnote)
                            .textFont(.footnote)
                            .foregroundStyle(Palette.subtext)
                            .padding(.leading, 8)
                    }

                    if model.isWorking {
                        ProgressView()
                            .frame(maxWidth: .infinity)
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
        .task {
            await model.load()
        }
        .task {
            await model.observePending()
        }
        .confirmation(
            isPresented: $model.isChoosing,
            systemImage: "icloud",
            title: "iCloud にもデータがあります",
            message: "使う方を選んでください。選ばなかった方は置き換わります",
            keepTitle: "やめる",
            confirmTitle: "iCloud のデータを使う",
            alternateTitle: "この iPhone のデータを使う",
            role: .suggestion,
            onAlternate: {
                Task {
                    await model.useLocalData()
                }
            }
        ) {
            Task {
                await model.useCloudData()
            }
        }
    }
}

private extension SyncView {
    static let onOptions: [CapsulePicker<Bool>.Option] = [
        .init("オフ", value: false),
        .init("オン", value: true)
    ]

    func note(
        _ systemImage: String,
        _ text: String
    ) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Image(systemName: systemImage)
                .sansFont(.caption, weight: .medium)
                .foregroundStyle(Palette.accent)
                .frame(width: 22)

            Text(text)
                .textFont(.footnote)
                .foregroundStyle(Palette.text)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

private extension SyncView {
    var canChange: Bool {
        model.isOn || model.isAvailable
    }

    var footnote: String {
        model.isAvailable || model.isOn
            ? "切っても、この iPhone のデータは残ります"
            : "設定アプリで iCloud にサインインすると使えます"
    }

    var onBinding: Binding<Bool> {
        Binding {
            model.isOn
        } set: { isOn in
            Task {
                await model.setOn(isOn)
            }
        }
    }

    func pendingText(_ count: Int) -> String {
        count > 0 ? "iCloud に送っています（残り \(count) 件）" : "最新の状態です"
    }
}

#Preview {
    if let database = try? AppDatabase.inMemory() {
        NavigationStack {
            SyncView(
                model: SyncModel(
                    database: database,
                    cloud: .unavailable
                )
            )
        }
    }
}
