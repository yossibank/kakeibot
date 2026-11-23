import Core
import DesignSystem
import SwiftUI

extension Wallet.Kind.Role {
    func balanceLabel(_ balance: Int) -> String? {
        switch self {
        case .card: balance > 0 ? "返ってくる額" : "未払い"
        case .loan: "残り"
        case .onHand, .investment: nil
        }
    }

    func balanceColor(_ balance: Int) -> Color {
        switch self {
        case .card: balance > 0 ? Palette.accent : Palette.text

        case .loan: Palette.text

        case .onHand, .investment:
            balance < 0 ? Palette.rose : Palette.accentStrong
        }
    }
}
