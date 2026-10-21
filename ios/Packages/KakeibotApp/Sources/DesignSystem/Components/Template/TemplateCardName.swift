import SwiftUI

public struct TemplateCardName: View {
    @Environment(\.themeStyle) private var themeStyle

    let name: String
    let size: TemplateCardSize

    public init(
        name: String,
        size: TemplateCardSize
    ) {
        self.name = name
        self.size = size
    }

    public var body: some View {
        Text(name)
            .font(size.nameFont(in: themeStyle))
            .foregroundStyle(Palette.accentStrong)
    }
}
