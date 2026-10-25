import DesignSystem
import SwiftUI

struct IconEditorDrawer<Field: Hashable>: ViewModifier {
    @Binding var isPresented: Bool

    @State private var top: CGFloat = 0

    let model: IconEditModel
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

                        SettingsDrawer("アイコン", isFloating: true) {
                            close()
                        } content: {
                            ScrollView {
                                IconEditor(
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
                        .padding(.horizontal, 12)
                        .padding(.bottom, 8)
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
        model: IconEditModel,
        focus: FocusState<Field?>.Binding,
        textField: Field,
        below: CGFloat
    ) -> some View {
        modifier(
            IconEditorDrawer(
                isPresented: isPresented,
                model: model,
                focus: focus,
                textField: textField,
                below: below
            )
        )
    }
}

private extension IconEditorDrawer {
    static var gap: CGFloat {
        12
    }

    var inset: CGFloat {
        max(below - top + Self.gap, 0)
    }

    func close() {
        focus.wrappedValue = nil
        isPresented = false
    }
}
