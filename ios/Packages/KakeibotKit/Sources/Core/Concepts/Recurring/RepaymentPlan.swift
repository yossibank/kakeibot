public struct RepaymentPlan: Hashable, Sendable {
    public let count: Int
    public let finalAmount: Int?
    public let gap: Int

    public init?(
        owed: Int,
        amount: Int,
        count: Int? = nil
    ) {
        guard
            owed > 0,
            amount > 0
        else {
            return nil
        }

        let count = count ?? max(owed / amount, 1)

        guard count > 0 else {
            return nil
        }

        let last = owed - amount * (count - 1)
        let fits = last > 0 && last < amount * 2

        self.count = count
        self.finalAmount = fits && last != amount ? last : nil
        self.gap = fits ? 0 : amount * count - owed
    }
}
