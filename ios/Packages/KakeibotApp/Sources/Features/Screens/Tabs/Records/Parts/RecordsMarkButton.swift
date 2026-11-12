import SwiftUI

struct RecordsMarkButton<Label: View>: View {
    @State private var frame: CGRect = .zero

    let action: (CGRect) -> Void
    let label: Label

    init(
        action: @escaping (CGRect) -> Void,
        @ViewBuilder label: () -> Label
    ) {
        self.action = action
        self.label = label()
    }

    var body: some View {
        Button {
            action(frame)
        } label: {
            label
        }
        .buttonStyle(.plain)
        .onGeometryChange(for: CGRect.self) { proxy in
            proxy.frame(in: .global)
        } action: { frame in
            self.frame = frame
        }
    }
}
