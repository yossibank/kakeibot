import DesignSystem
import SwiftUI

struct SettingsSwitch: View {
    @Environment(\.themeStyle.corner) private var corner

    let title: String
    let detail: String
    let systemImage: String
    let isOn: Bool
    let change: (Bool) async -> Void

    var body: some View {
        GoldSwitch(isOn: binding, systemImage: systemImage) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .textFont(.subheadline)
                    .foregroundStyle(Palette.text)

                Text(detail)
                    .textFont(.caption)
                    .foregroundStyle(Palette.subtext)
            }
        }
        .background(Palette.panel, in: .rect(cornerRadius: corner.radius(16)))
    }
}

private extension SettingsSwitch {
    var binding: Binding<Bool> {
        Binding {
            isOn
        } set: { value in
            Task {
                await change(value)
            }
        }
    }
}
