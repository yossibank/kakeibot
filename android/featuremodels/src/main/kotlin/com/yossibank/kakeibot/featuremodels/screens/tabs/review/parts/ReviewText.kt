package com.yossibank.kakeibot.featuremodels.screens.tabs.review.parts

import com.yossibank.kakeibot.core.concepts.review.ReviewPeriod
import com.yossibank.kakeibot.core.shared.Percent

object ReviewText {
    fun shares(amounts: List<Long>): List<String?> {
        val whole = amounts.sum()
        val percents = Percent.shares(amounts)

        return amounts.zip(percents) { amount, percent ->
            share(
                amount = amount,
                percent = percent,
                whole = whole,
            )
        }
    }

    fun balanceTitle(amount: Long): String = when {
        amount > 0 -> "収支 · 黒字"
        amount < 0 -> "収支 · 赤字"
        else -> "収支"
    }

    fun previousName(
        scale: ReviewPeriod.Scale,
        isPartial: Boolean,
    ): String = when (scale) {
        ReviewPeriod.Scale.week -> if (isPartial) "前の週の同じ曜日まで" else "前の週"
        ReviewPeriod.Scale.month -> if (isPartial) "前の月の同じ日まで" else "前の月"
        ReviewPeriod.Scale.year -> if (isPartial) "前の年の同じ日まで" else "前の年"
    }

    private fun share(
        amount: Long,
        percent: Int,
        whole: Long,
    ): String? {
        if (amount <= 0 || whole <= 0) {
            return "0%"
        }

        if (amount * 100 < whole) {
            return null
        }

        if (percent >= 100 && amount < whole) {
            val tenths = amount * 1000 / whole
            return "${tenths / 10}.${tenths % 10}%"
        }

        return "$percent%"
    }
}
