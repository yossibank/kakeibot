package com.yossibank.kakeibot.core.shared

object Percent {
    fun floor(
        part: Long,
        of: Long,
    ): Int {
        if (of <= 0) {
            return 0
        }

        val percent = (part * 100 / of).toInt()

        return percent.coerceIn(0, 100)
    }

    fun shares(parts: List<Long>): List<Int> {
        val whole = parts.sum()

        if (whole <= 0) {
            return parts.map { 0 }
        }

        val percents = parts.map { (it * 100 / whole).toInt() }.toMutableList()
        val rest = 100 - percents.sum()

        val order = parts.indices.sortedWith { lhs, rhs ->
            val lhsRest = parts[lhs] * 100 % whole
            val rhsRest = parts[rhs] * 100 % whole

            if (lhsRest == rhsRest) lhs.compareTo(rhs) else rhsRest.compareTo(lhsRest)
        }

        for (index in order.take(rest)) {
            percents[index] += 1
        }

        return percents
    }
}
