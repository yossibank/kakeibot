package com.yossibank.kakeibot.core.concepts.recurring

import com.yossibank.kakeibot.core.concepts.date.LocalDate

data class LoanPayoff(
    val count: Int,
    val lastDate: LocalDate,
) {
    private data class Payment(
        val date: LocalDate,
        val amount: Int,
    )

    companion object {
        private const val searchYears = 100
        private const val daysPerSearch = 365

        fun of(
            balance: Long,
            repayments: List<Recurring>,
            after: LocalDate,
        ): LoanPayoff? {
            val paying = repayments.filter { it.amount > 0 }
            var remaining = -balance

            if (remaining <= 0 || paying.isEmpty()) {
                return null
            }

            var count = 0
            var start = after.adding(days = 1)

            repeat(searchYears) {
                val end = start.adding(days = daysPerSearch)

                val payments = paying
                    .flatMap { recurring ->
                        recurring.dates(
                            from = start,
                            through = end,
                        ).map { date ->
                            Payment(
                                date = date,
                                amount = recurring.scheduledAmount(paidOn = date),
                            )
                        }
                    }
                    .sortedBy { it.date }

                for (payment in payments) {
                    remaining -= payment.amount
                    count += 1

                    if (remaining <= 0) {
                        return LoanPayoff(
                            count = count,
                            lastDate = payment.date,
                        )
                    }
                }

                start = end.adding(days = 1)
            }

            return null
        }
    }
}
