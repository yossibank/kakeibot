import Core
import CoreGraphics

public extension ThemeCorner {
    func radius(_ base: CGFloat) -> CGFloat {
        (base * scale).rounded()
    }
}
