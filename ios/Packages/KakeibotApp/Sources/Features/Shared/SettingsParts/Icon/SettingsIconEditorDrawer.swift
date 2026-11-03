import DesignSystem
import SwiftUI

struct SettingsIconEditorDrawer<Field: Hashable>: ViewModifier {
    @Binding var isPresented: Bool

    @State private var top: CGFloat = 0

    let model: SettingsIconEditorModel
    let focus: FocusState<Field?>.Binding
    let textField: Field
    let below: CGFloat

    func body(content: Content) -> some View {
        content
            .overlay {
                if isPresented {
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
                top = minY
            }
            .animation(.snappy, value: isPresented)
    }
}

extension View {
    func iconEditorDrawer<Field: Hashable>(
        isPresented: Binding<Bool>,
        model: SettingsIconEditorModel,
        focus: FocusState<Field?>.Binding,
        textField: Field,
        below: CGFloat
    ) -> some View {
        modifier(
            SettingsIconEditorDrawer(
                isPresented: isPresented,
                model: model,
                focus: focus,
                textField: textField,
                below: below
            )
        )
    }
}

private extension SettingsIconEditorDrawer {
    static var gap: CGFloat {
        16
    }

    var inset: CGFloat {
        max(below - top + Self.gap, 0)
    }

    func close() {
        focus.wrappedValue = nil
        isPresented = false
    }
}
