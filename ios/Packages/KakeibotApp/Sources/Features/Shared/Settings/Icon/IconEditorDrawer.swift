import DesignSystem
import SwiftUI

extension View {
    func iconEditorDrawer<Field: Hashable>(
        isPresented: Binding<Bool>,
        model: IconEditModel,
        focus: FocusState<Field?>.Binding,
        textField: Field
    ) -> some View {
        overlay(alignment: .bottom) {
            if isPresented.wrappedValue {
                Palette.scrim
                    .opacity(0.35)
                    .ignoresSafeArea()
                    .onTapGesture {
                        focus.wrappedValue = nil
                        isPresented.wrappedValue = false
                    }
                    .transition(.opacity)

                SettingsDrawer("アイコン") {
                    focus.wrappedValue = nil
                    isPresented.wrappedValue = false
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
                    .frame(maxHeight: 420)
                }
                .transition(.settingsDrawer)
            }
        }
        .animation(.snappy, value: isPresented.wrappedValue)
    }
}
