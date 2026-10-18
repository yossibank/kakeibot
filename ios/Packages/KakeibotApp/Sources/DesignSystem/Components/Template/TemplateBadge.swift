import Core
import SwiftUI

struct TemplateBadge: View {
    let icon: Icon?
    let size: TemplateCardSize

    var body: some View {
        IconImage(icon, size: size.iconSize)
            .foregroundStyle(Palette.gold)
            .frame(width: size.badgeSize, height: size.badgeSize)
            .background(Palette.faint, in: Circle())
            .overlay {
                Circle()
                    .strokeBorder(TemplateCardStyle.foil, lineWidth: 1)
            }
    }
}
