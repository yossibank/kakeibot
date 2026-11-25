import DesignSystem
import FeatureModels
import SwiftUI

struct SettingsIconEditorDrawer<Field: Hashable>: ViewModifier {
    @State private var layout = Layout()

    let model: SettingsIconEditorModel
    let focus: FocusState<Field?>.Binding
    let textField: Field
    let below: CGFloat

    func body(content: Content) -> some View {
        content
            .overlay {
                if model.isPresented {
                    VStack(spacing: 0) {
                        Color.clear
                            .frame(height: inset)
                            .contentShape(.rect)
                            .onTapGesture {
                                close()
                            }

                        SettingsDrawer("アイコン") {
                            close()
                        } content: {
                            ScrollView {
                                SettingsIconEditor(
                                    model: model,
                                    focus: focus,
                                    textField: textField
                                )
                                .padding(.bottom, 8)
                            }
                            .scrollIndicators(.hidden)
                            .scrollDismissesKeyboard(.interactively)
                            .frame(maxHeight: .infinity)
                        }
                    }
                    .transition(.settingsDrawer)
                }
            }
            .onGeometryChange(for: CGFloat.self) { proxy in
                proxy.frame(in: .global).minY
            } action: { minY in
                layout.top = minY
            }
            .animation(.snappy, value: model.isPresented)
    }
}

extension View {
    func iconEditorDrawer<Field: Hashable>(
        model: SettingsIconEditorModel,
        focus: FocusState<Field?>.Binding,
        textField: Field,
        below: CGFloat
    ) -> some View {
        modifier(
            SettingsIconEditorDrawer(
                model: model,
                focus: focus,
                textField: textField,
                below: below
            )
        )
    }
}

private extension SettingsIconEditorDrawer {
    struct Layout {
        var top: CGFloat = 0
    }

    static var gap: CGFloat {
        16
    }

    var inset: CGFloat {
        max(below - layout.top + Self.gap, 0)
    }

    func close() {
        focus.wrappedValue = nil
        model.dismiss()
    }
}
