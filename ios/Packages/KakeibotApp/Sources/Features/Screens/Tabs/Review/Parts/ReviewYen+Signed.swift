import Core

extension ReviewYen {
    static func signed(_ amount: Int) -> String {
        if amount > 0 {
            return "+\(text(amount))"
        }

        return amount < 0 ? "−\(text(-amount))" : "±0円"
    }

    static func signedNumber(_ amount: Int) -> String {
        if amount > 0 {
            return "+\(number(amount))"
        }

        return amount < 0 ? "−\(number(-amount))" : "±0"
    }
}
