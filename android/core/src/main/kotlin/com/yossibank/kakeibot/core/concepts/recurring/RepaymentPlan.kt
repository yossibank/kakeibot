package com.yossibank.kakeibot.core.concepts.recurring

@ConsistentCopyVisibility
data class RepaymentPlan private constructor(
    val count: Int,
    val finalAmount: Int?,
    val gap: Long,
) {
    companion object {
        fun of(
            owed: Int,
            amount: Int,
            count: Int? = null,
        ): RepaymentPlan? {
            if (owed <= 0 || amount <= 0) {
                return null
            }

            val planned = count ?: maxOf(owed / amount, 1)

            if (planned <= 0) {
                return null
            }

            val last = owed.toLong() - amount.toLong() * (planned - 1)
            val fits = last > 0 && last < amount.toLong() * 2

            return RepaymentPlan(
                count = planned,
                finalAmount = if (fits && last != amount.toLong()) last.toInt() else null,
                gap = if (fits) 0L else amount.toLong() * planned - owed,
            )
        }
    }
}
