import CoreGraphics

public enum MenuPlacement {
    public static func trailingX(
        of anchor: CGRect,
        panelWidth: CGFloat,
        in width: CGFloat,
        inset: CGFloat
    ) -> CGFloat {
        let preferred = anchor.maxX - panelWidth
        let limit = width - panelWidth - inset
        let lower = max(preferred, inset)
        return min(lower, limit)
    }
}
