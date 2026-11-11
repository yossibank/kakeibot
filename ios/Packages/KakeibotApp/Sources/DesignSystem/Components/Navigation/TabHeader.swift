import SwiftUI

public struct TabHeader<Accessory: View>: View {
    let title: String
    let subtitle: String?
    let accessory: Accessory

    public init(
        _ title: String,
        subtitle: String? = nil,
        @ViewBuilder accessory: () -> Accessory
    ) {
        self.title = title
        self.subtitle = subtitle
        self.accessory = accessory()
    }

    public var body: some View {
        HStack {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(title)
                    .displayFont(.headline)
                    .tracking(3)
                    .foregroundStyle(Palette.accentStrong)

                if let subtitle {
                    Text(subtitle)
                        .textFont(.caption)
                        .foregroundStyle(Palette.subtext)
                }
            }

            Spacer()

            accessory
        }
        .frame(minHeight: Self.height)
    }
}

public extension TabHeader where Accessory == EmptyView {
    init(_ title: String) {
        self.init(title) {
            EmptyView()
        }
    }
}

private extension TabHeader {
    static var height: CGFloat {
        44
    }
}

#Preview {
    VStack(spacing: 12) {
        TabHeader("11月", subtitle: "10/25〜11/24") {
            HeaderButton(systemImage: "gearshape") {}
        }

        TabHeader("記録")
    }
    .padding()
    .background(Palette.background)
}
