import SwiftUI

public extension View {
    func tapArea(_ length: CGFloat) -> some View {
        tapArea(
            EdgeInsets(
                top: length,
                leading: length,
                bottom: length,
                trailing: length
            )
        )
    }

    func tapArea(_ outsets: EdgeInsets) -> some View {
        let insets = EdgeInsets(
            top: -outsets.top,
            leading: -outsets.leading,
            bottom: -outsets.bottom,
            trailing: -outsets.trailing
        )

        return padding(outsets)
            .contentShape(.rect)
            .padding(insets)
    }
}
