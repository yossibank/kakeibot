import SwiftUI

struct RecordsMarkButton<Label: View>: View {
    @State private var layout = Layout()

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
            action(layout.frame)
        } label: {
            label
        }
        .buttonStyle(.plain)
        .onGeometryChange(for: CGRect.self) { proxy in
            proxy.frame(in: .global)
        } action: { frame in
            layout.frame = frame
        }
    }
}

private extension RecordsMarkButton {
    struct Layout {
        var frame: CGRect = .zero
    }
}
